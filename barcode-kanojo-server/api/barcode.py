import asyncio
import logging
import time

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from models.database import get_db
from models.kanojo import Kanojo
from models.product import Product
from models.activity import ScanHistory
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response, error_response
from services.barcode_generator import generate_kanojo_attributes
from services.avatar_composer import generate_and_save

log = logging.getLogger(__name__)
router = APIRouter()


@router.get("/query.json")
async def query(
    barcode: str,
    format: str = "",
    extension: str = "",
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Check if a kanojo exists for this barcode."""
    # Look up existing kanojo
    result = await db.execute(select(Kanojo).where(Kanojo.barcode == barcode))
    kanojo = result.scalar_one_or_none()

    # Look up product
    result = await db.execute(select(Product).where(Product.barcode == barcode))
    product = result.scalar_one_or_none()

    # Look up scan history
    result = await db.execute(
        select(ScanHistory).where(ScanHistory.barcode == barcode, ScanHistory.user_id == user.id)
    )
    scan_history = result.scalar_one_or_none()

    response_data = {}
    if kanojo:
        response_data["kanojo"] = kanojo.to_api_dict()
        if kanojo.owner_user_id:
            result = await db.execute(select(User).where(User.id == kanojo.owner_user_id))
            owner = result.scalar_one_or_none()
            if owner:
                response_data["owner_user"] = owner.to_api_dict()
    if product:
        response_data["product"] = product.to_api_dict()
    if scan_history:
        response_data["scan_history"] = scan_history.to_api_dict()

    # Barcode data with generated attributes preview
    barcode_data = generate_kanojo_attributes(barcode)
    barcode_data["barcode"] = barcode
    response_data["barcode"] = barcode_data

    return api_response(code=200, message="OK", **response_data)


@router.post("/scan.json")
async def scan(
    barcode: str = Form(...),
    company_name: str = Form(""),
    product_name: str = Form(""),
    product_category_id: int = Form(1),
    product_comment: str = Form(""),
    product_image_data: UploadFile | None = File(None),
    product_geo: str = Form(""),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record a barcode scan and create/update product."""
    # Create or update product
    result = await db.execute(select(Product).where(Product.barcode == barcode))
    product = result.scalar_one_or_none()
    if not product:
        product = Product(
            barcode=barcode, name=product_name, company_name=company_name,
            category_id=product_category_id, comment=product_comment,
        )
        db.add(product)
    else:
        product.scan_count += 1

    # Update scan history
    result = await db.execute(
        select(ScanHistory).where(ScanHistory.barcode == barcode, ScanHistory.user_id == user.id)
    )
    scan_history = result.scalar_one_or_none()
    if not scan_history:
        scan_history = ScanHistory(
            user_id=user.id, barcode=barcode,
            total_count=1, scanned_at=int(time.time()),
        )
        db.add(scan_history)
    else:
        scan_history.total_count += 1
        scan_history.scanned_at = int(time.time())

    user.scan_count += 1
    await db.commit()

    # Check if kanojo exists
    result = await db.execute(select(Kanojo).where(Kanojo.barcode == barcode))
    kanojo = result.scalar_one_or_none()

    response_data = {"scan_history": scan_history.to_api_dict()}
    if kanojo:
        response_data["kanojo"] = kanojo.to_api_dict()

    return api_response(code=200, message="OK", **response_data)


@router.post("/scan_and_generate.json")
async def scan_and_generate(
    barcode: str = Form(...),
    company_name: str = Form(""),
    kanojo_name: str = Form(""),
    product_name: str = Form(""),
    product_category_id: int = Form(1),
    product_comment: str = Form(""),
    kanojo_profile_image_data: UploadFile | None = File(None),
    product_image_data: UploadFile | None = File(None),
    product_geo: str = Form(""),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Scan barcode and generate a new kanojo."""
    # Check if kanojo already exists for this barcode
    result = await db.execute(select(Kanojo).where(Kanojo.barcode == barcode))
    existing = result.scalar_one_or_none()
    if existing:
        return error_response(409, "Kanojo already exists for this barcode")

    # Create product
    result = await db.execute(select(Product).where(Product.barcode == barcode))
    product = result.scalar_one_or_none()
    if not product:
        product = Product(
            barcode=barcode, name=product_name, company_name=company_name,
            category_id=product_category_id, comment=product_comment,
        )
        db.add(product)
        await db.flush()

    # Generate kanojo attributes from barcode
    attrs = generate_kanojo_attributes(barcode)
    kanojo = Kanojo(
        name=kanojo_name or f"Kanojo #{barcode[-4:]}",
        barcode=barcode,
        owner_user_id=user.id,
        relation_status=2,  # KANOJO
        love_gauge=75,
        **attrs,
    )
    db.add(kanojo)

    # Update user stats
    user.kanojo_count += 1
    user.generate_count += 1
    user.scan_count += 1

    # Create scan history
    scan_history = ScanHistory(
        user_id=user.id, barcode=barcode,
        total_count=1, kanojo_count=1, scanned_at=int(time.time()),
    )
    db.add(scan_history)

    await db.commit()
    await db.refresh(kanojo)

    # Generate avatar images asynchronously (non-blocking)
    kanojo_id = kanojo.id
    output_dir = settings.UPLOAD_DIR / "profile_images" / "kanojo" / str(kanojo_id)
    kanojo_dict = kanojo.to_api_dict()
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, generate_and_save, kanojo_id, kanojo_dict, output_dir)

    return api_response(
        code=200, message="OK",
        user=user.to_api_dict(),
        kanojo=kanojo.to_api_dict(),
        scan_history=scan_history.to_api_dict(),
    )


@router.get("/decrease_generating.json")
async def decrease_generating(
    barcode: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel kanojo generation, restore user's generate count."""
    result = await db.execute(select(Product).where(Product.barcode == barcode))
    product = result.scalar_one_or_none()

    return api_response(
        code=200, message="OK",
        user=user.to_api_dict(),
        product=product.to_api_dict() if product else {},
    )


@router.post("/update.json")
async def barcode_update(
    barcode: str = Form(...),
    company_name: str = Form(""),
    product_name: str = Form(""),
    product_category_id: int = Form(1),
    product_comment: str = Form(""),
    product_image_data: UploadFile | None = File(None),
    product_geo: str = Form(""),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update product information for a barcode."""
    result = await db.execute(select(Product).where(Product.barcode == barcode))
    product = result.scalar_one_or_none()
    if not product:
        return error_response(404, "Product not found")

    if company_name:
        product.company_name = company_name
    if product_name:
        product.name = product_name
    if product_category_id:
        product.category_id = product_category_id
    if product_comment:
        product.comment = product_comment

    await db.commit()
    return api_response(code=200, message="OK")
