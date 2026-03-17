from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.activity import Activity
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response

router = APIRouter()


@router.get("/activity/user_timeline.json")
async def user_timeline(
    user_id: int = 0,
    since_id: int = 0,
    index: int = 0,
    limit: int = 20,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_user_id = user_id if user_id > 0 else user.id
    query = select(Activity).where(Activity.user_id == target_user_id)
    if since_id > 0:
        query = query.where(Activity.id > since_id)
    query = query.order_by(Activity.id.desc()).offset(index).limit(limit)

    result = await db.execute(query)
    activities = result.scalars().all()
    return api_response(
        code=200, message="OK",
        activities=[a.to_api_dict() for a in activities],
    )


@router.get("/api/activity/scanned_timeline.json")
async def scanned_timeline(
    barcode: str = "",
    since_id: int = 0,
    index: int = 0,
    limit: int = 20,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Activity).order_by(Activity.id.desc()).offset(index).limit(limit)
    result = await db.execute(query)
    activities = result.scalars().all()
    return api_response(
        code=200, message="OK",
        activities=[a.to_api_dict() for a in activities],
    )


@router.get("/api/activity/kanojo_timeline.json")
async def kanojo_timeline(
    kanojo_id: int = 0,
    index: int = 0,
    limit: int = 20,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Activity).where(Activity.kanojo_id == kanojo_id)
    query = query.order_by(Activity.id.desc()).offset(index).limit(limit)

    result = await db.execute(query)
    activities = result.scalars().all()
    return api_response(
        code=200, message="OK",
        activities=[a.to_api_dict() for a in activities],
    )
