from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.kanojo import Kanojo
from models.activity import KanojoVote
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response, error_response

router = APIRouter()


@router.get("/show.json")
async def show(
    kanojo_id: int,
    screen: str = "",
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Kanojo).where(Kanojo.id == kanojo_id))
    kanojo = result.scalar_one_or_none()
    if not kanojo:
        return error_response(404, "Kanojo not found")

    response_data = {"kanojo": kanojo.to_api_dict()}

    # Include owner user
    if kanojo.owner_user_id:
        result = await db.execute(select(User).where(User.id == kanojo.owner_user_id))
        owner = result.scalar_one_or_none()
        if owner:
            response_data["owner_user"] = owner.to_api_dict()

    return api_response(code=200, message="OK", **response_data)


@router.get("/like_rankings.json")
async def like_rankings(
    index: int = 0,
    limit: int = 20,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Kanojo)
        .order_by(Kanojo.like_rate.desc())
        .offset(index)
        .limit(limit)
    )
    kanojos = result.scalars().all()
    return api_response(
        code=200, message="OK",
        like_ranking_kanojos=[k.to_api_dict() for k in kanojos],
    )


@router.post("/vote_like.json")
async def vote_like(
    kanojo_id: int,
    like: bool = True,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Kanojo).where(Kanojo.id == kanojo_id))
    kanojo = result.scalar_one_or_none()
    if not kanojo:
        return error_response(404, "Kanojo not found")

    # Check existing vote
    result = await db.execute(
        select(KanojoVote).where(
            KanojoVote.user_id == user.id, KanojoVote.kanojo_id == kanojo_id
        )
    )
    vote = result.scalar_one_or_none()

    if vote:
        if vote.voted_like != like:
            vote.voted_like = like
            kanojo.like_rate += 1 if like else -1
    else:
        vote = KanojoVote(user_id=user.id, kanojo_id=kanojo_id, voted_like=like)
        db.add(vote)
        if like:
            kanojo.like_rate += 1
            kanojo.follower_count += 1

    await db.commit()
    await db.refresh(kanojo)
    return api_response(code=200, message="OK", kanojo=kanojo.to_api_dict())
