from fastapi import APIRouter, Depends, File, Form, Response, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.user import User
from middleware.auth_middleware import get_current_user
from schemas.common import api_response, error_response
from services.auth import create_session, signup_user, verify_user

router = APIRouter()


@router.post("/signup.json")
async def signup(
    response: Response,
    uuid: str = Form(...),
    name: str = Form(""),
    email: str = Form(...),
    password: str = Form(...),
    birth_year: int = Form(2000),
    birth_month: int = Form(1),
    birth_day: int = Form(1),
    sex: str = Form(""),
    profile_image_data: UploadFile | None = File(None),
    db: AsyncSession = Depends(get_db),
):
    try:
        user = await signup_user(
            db, uuid=uuid, name=name, email=email, password=password,
            birth_year=birth_year, birth_month=birth_month, birth_day=birth_day, sex=sex,
        )
    except Exception as e:
        err = str(e).lower()
        if "uuid" in err:
            return error_response(409, "Device already has an account. Please log in instead.")
        return error_response(409, "Email already registered")

    # Create session and set cookie
    token = await create_session(db, user.id)
    response.set_cookie("session_token", token, httponly=True, max_age=30 * 24 * 3600)

    # TODO: handle profile_image_data upload

    return api_response(code=200, message="OK", user=user.to_api_dict())


@router.post("/verify.json")
async def verify(
    response: Response,
    uuid: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    db: AsyncSession = Depends(get_db),
):
    """Login endpoint. The client sends raw password; server hashes with stored salt."""
    user = await verify_user(db, uuid=uuid, email=email, password_hash=password)
    if not user:
        return error_response(401, "Invalid credentials")

    token = await create_session(db, user.id)
    response.set_cookie("session_token", token, httponly=True, max_age=30 * 24 * 3600)

    return api_response(code=200, message="OK", user=user.to_api_dict())


@router.get("/show.json")
async def show(user: User = Depends(get_current_user)):
    return api_response(code=200, message="OK", user=user.to_api_dict())


@router.post("/update.json")
async def update(
    name: str = Form(None),
    current_password: str = Form(None),
    new_password: str = Form(None),
    email: str = Form(None),
    birth_year: int = Form(None),
    birth_month: int = Form(None),
    birth_day: int = Form(None),
    sex: str = Form(None),
    profile_image_data: UploadFile | None = File(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if name is not None:
        user.name = name
    if email is not None:
        user.email = email
    if birth_year is not None:
        user.birth_year = birth_year
    if birth_month is not None:
        user.birth_month = birth_month
    if birth_day is not None:
        user.birth_day = birth_day
    if sex is not None:
        user.sex = sex

    # TODO: handle password change and profile_image_data upload

    await db.commit()
    await db.refresh(user)
    return api_response(code=200, message="OK", user=user.to_api_dict())


@router.post("/delete.json")
async def delete(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.delete(user)
    await db.commit()
    return api_response(code=200, message="OK")
