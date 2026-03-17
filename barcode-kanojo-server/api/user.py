from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.kanojo import Kanojo
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response

router = APIRouter()


@router.get("/user/current_kanojos.json")
async def current_kanojos(
    index: int = 0,
    limit: int = 20,
    search: str = "",
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Kanojo).where(Kanojo.owner_user_id == user.id)
    if search:
        query = query.where(Kanojo.name.ilike(f"%{search}%"))
    query = query.order_by(Kanojo.id.desc()).offset(index).limit(limit)

    result = await db.execute(query)
    kanojos = result.scalars().all()

    return api_response(
        code=200, message="OK",
        user=user.to_api_dict(),
        current_kanojos=[k.to_api_dict() for k in kanojos],
        search_result={"hit_count": len(kanojos)},
    )


@router.get("/api/user/friend_kanojos.json")
async def friend_kanojos(
    index: int = 0,
    limit: int = 20,
    search: str = "",
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # For now, return kanojos not owned by the current user
    query = select(Kanojo).where(Kanojo.owner_user_id != user.id)
    if search:
        query = query.where(Kanojo.name.ilike(f"%{search}%"))
    query = query.order_by(Kanojo.id.desc()).offset(index).limit(limit)

    result = await db.execute(query)
    kanojos = result.scalars().all()

    return api_response(
        code=200, message="OK",
        friend_kanojos=[k.to_api_dict() for k in kanojos],
        search_result={"hit_count": len(kanojos)},
    )
