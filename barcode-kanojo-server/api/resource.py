from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.product import ProductCategory
from schemas.common import api_response

router = APIRouter()


@router.get("/product_category_list.json")
async def product_category_list(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ProductCategory).order_by(ProductCategory.id))
    categories = result.scalars().all()

    if not categories:
        # Return default categories if none seeded
        default_categories = [
            {"id": 1, "name": "Food"},
            {"id": 2, "name": "Drink"},
            {"id": 3, "name": "Snack"},
            {"id": 4, "name": "Daily"},
            {"id": 5, "name": "Book"},
            {"id": 6, "name": "Game"},
            {"id": 7, "name": "Music"},
            {"id": 8, "name": "Electronics"},
            {"id": 9, "name": "Fashion"},
            {"id": 10, "name": "Other"},
        ]
        return api_response(code=200, message="OK", categories=default_categories)

    return api_response(
        code=200, message="OK",
        categories=[c.to_api_dict() for c in categories],
    )
