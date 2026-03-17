import hashlib
import secrets
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from models.session import Session
from models.user import User


def hash_password(password: str, salt: str) -> str:
    """SHA-512 hash matching Android Password.kt: SHA-512(password + salt), uppercase hex."""
    combined = (password + salt).encode("utf-8")
    return hashlib.sha512(combined).hexdigest().upper()


def generate_salt() -> str:
    return secrets.token_hex(16)


def generate_session_token() -> str:
    return secrets.token_hex(64)


async def create_session(db: AsyncSession, user_id: int) -> str:
    token = generate_session_token()
    session = Session(
        user_id=user_id,
        session_token=token,
        expires_at=datetime.utcnow() + timedelta(hours=settings.SESSION_EXPIRY_HOURS),
    )
    db.add(session)
    await db.commit()
    return token


async def get_user_from_session(db: AsyncSession, session_token: str | None) -> User | None:
    if not session_token:
        return None
    result = await db.execute(
        select(Session).where(
            Session.session_token == session_token,
            Session.expires_at > datetime.utcnow(),
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        return None
    result = await db.execute(select(User).where(User.id == session.user_id))
    return result.scalar_one_or_none()


async def signup_user(
    db: AsyncSession,
    uuid: str,
    name: str,
    email: str,
    password: str,
    birth_year: int = 2000,
    birth_month: int = 1,
    birth_day: int = 1,
    sex: str = "",
) -> User:
    salt = generate_salt()
    password_hashed = hash_password(password, salt)
    user = User(
        uuid=uuid,
        name=name,
        email=email,
        password_hash=password_hashed,
        password_salt=salt,
        birth_year=birth_year,
        birth_month=birth_month,
        birth_day=birth_day,
        sex=sex,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def verify_user(db: AsyncSession, uuid: str, email: str, password_hash: str) -> User | None:
    """Verify login. The client sends the already-hashed password (SHA-512 of password+salt).
    But since we store our own salt, we need to handle this differently.
    The Android client hashes as: SHA-512(raw_password + email_as_salt).toUpperCase()
    So we receive the pre-hashed value and compare against our stored hash.

    For simplicity in our custom backend, the client will send the raw password
    and we hash it server-side with our salt. This requires the iOS client to
    send raw passwords over HTTPS."""
    result = await db.execute(
        select(User).where(User.uuid == uuid, User.email == email)
    )
    user = result.scalar_one_or_none()
    if not user:
        return None
    expected_hash = hash_password(password_hash, user.password_salt)
    if user.password_hash == expected_hash:
        return user
    return None
