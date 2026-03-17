import time

from fastapi import APIRouter, Depends, Form
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.kanojo import Kanojo
from models.item import Item
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response, error_response

router = APIRouter()

# Category ID → display name mapping
_CATEGORY_NAMES = {
    1: "Flowers", 2: "Sweets", 3: "Accessories",
    4: "Casual", 5: "Entertainment", 6: "Dining",
}


def _cat_title(cat_id: int) -> str:
    return _CATEGORY_NAMES.get(cat_id, f"Category {cat_id}")


@router.get("/item_list.json")
async def item_list(
    kanojo_id: int,
    type_id: int = 0,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Gift item menu."""
    result = await db.execute(
        select(Item).where(Item.item_class == 1)  # GIFT_ITEM_CLASS
    )
    items = result.scalars().all()

    # Group by category
    categories: dict[int, list] = {}
    for item in items:
        cat_id = item.item_category_id or 0
        if cat_id not in categories:
            categories[cat_id] = []
        categories[cat_id].append(item.to_api_dict())

    item_categories = [
        {"item_category_id": cat_id, "title": _cat_title(cat_id), "items": cat_items}
        for cat_id, cat_items in categories.items()
    ]
    return api_response(code=200, message="OK", item_categories=item_categories)


@router.get("/date_list.json")
async def date_list(
    kanojo_id: int,
    type_id: int = 0,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Date item menu."""
    result = await db.execute(
        select(Item).where(Item.item_class == 2)  # DATE_ITEM_CLASS
    )
    items = result.scalars().all()

    categories: dict[int, list] = {}
    for item in items:
        cat_id = item.item_category_id or 0
        if cat_id not in categories:
            categories[cat_id] = []
        categories[cat_id].append(item.to_api_dict())

    item_categories = [
        {"item_category_id": cat_id, "title": _cat_title(cat_id), "items": cat_items}
        for cat_id, cat_items in categories.items()
    ]
    return api_response(code=200, message="OK", item_categories=item_categories)


@router.get("/has_items.json")
async def has_items(
    item_class: int,
    item_category_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Item).where(Item.item_class == item_class)
    )
    items = result.scalars().all()
    item_categories = [{"title": "Owned", "items": [i.to_api_dict() for i in items]}]
    return api_response(code=200, message="OK", item_categories=item_categories)


@router.get("/store_items.json")
async def store_items(
    item_class: int,
    item_category_id: int,
    pod: int = 0,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Item).where(Item.item_class == item_class)
    if pod > 0:
        query = query.where((Item.time_of_day == 0) | (Item.time_of_day == pod))
    result = await db.execute(query)
    items = result.scalars().all()

    item_categories = [{"title": "Store", "items": [i.to_api_dict() for i in items]}]
    return api_response(code=200, message="OK", item_categories=item_categories)


@router.get("/permanent_items.json")
async def permanent_items(
    item_class: int,
    item_category_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Item).where(Item.item_class == item_class))
    items = result.scalars().all()
    item_categories = [{"title": "Permanent", "items": [i.to_api_dict() for i in items]}]
    return api_response(code=200, message="OK", item_categories=item_categories)


@router.get("/permanent_sub_item.json")
async def permanent_sub_item(
    item_class: int,
    item_category_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return api_response(code=200, message="OK", item_categories=[])


async def _do_interaction(
    kanojo_id: int, item_id: int, pod: int,
    user: User, db: AsyncSession, love_delta: int = 5,
) -> dict:
    """Shared logic for date/gift interactions."""
    result = await db.execute(select(Kanojo).where(Kanojo.id == kanojo_id))
    kanojo = result.scalar_one_or_none()
    if not kanojo:
        return error_response(404, "Kanojo not found")

    kanojo.love_gauge = min(100, kanojo.love_gauge + love_delta)
    await db.commit()
    await db.refresh(kanojo)

    owner_user = None
    if kanojo.owner_user_id:
        result = await db.execute(select(User).where(User.id == kanojo.owner_user_id))
        owner_user = result.scalar_one_or_none()

    return api_response(
        code=200, message="OK",
        self_user=user.to_api_dict(),
        owner_user=owner_user.to_api_dict() if owner_user else {},
        kanojo=kanojo.to_api_dict(),
        love_increment={"increase_love": str(love_delta), "decrement_love": "0", "alertShow": "0"},
        kanojo_message={"messages": ["Thank you!"]},
    )


@router.post("/do_date.json")
async def do_date(
    kanojo_id: int = Form(...),
    basic_item_id: int = Form(...),
    pod: int = Form(0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _do_interaction(kanojo_id, basic_item_id, pod, user, db, love_delta=10)


@router.post("/do_extend_date.json")
async def do_extend_date(
    kanojo_id: int = Form(...),
    extend_item_id: int = Form(...),
    pod: int = Form(0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _do_interaction(kanojo_id, extend_item_id, pod, user, db, love_delta=5)


@router.post("/do_gift.json")
async def do_gift(
    kanojo_id: int = Form(...),
    basic_item_id: int = Form(...),
    pod: int = Form(0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _do_interaction(kanojo_id, basic_item_id, pod, user, db, love_delta=5)


@router.post("/do_extend_gift.json")
async def do_extend_gift(
    kanojo_id: int = Form(...),
    extend_item_id: int = Form(...),
    pod: int = Form(0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _do_interaction(kanojo_id, extend_item_id, pod, user, db, love_delta=3)


@router.post("/play_on_live2d.json")
async def play_on_live2d(
    kanojo_id: int = Form(...),
    actions: str = Form(""),
    pod: int = Form(0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _do_interaction(kanojo_id, 0, pod, user, db, love_delta=1)
