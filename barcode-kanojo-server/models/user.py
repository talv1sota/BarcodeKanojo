from datetime import datetime

from sqlalchemy import Integer, String, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    uuid: Mapped[str] = mapped_column(String(36), unique=True, nullable=False)
    name: Mapped[str | None] = mapped_column(String(100))
    email: Mapped[str | None] = mapped_column(String(255), unique=True)
    password_hash: Mapped[str | None] = mapped_column(String(128))
    password_salt: Mapped[str | None] = mapped_column(String(64))
    birth_year: Mapped[int] = mapped_column(Integer, default=2000)
    birth_month: Mapped[int] = mapped_column(Integer, default=1)
    birth_day: Mapped[int] = mapped_column(Integer, default=1)
    sex: Mapped[str | None] = mapped_column(String(10))
    language: Mapped[str | None] = mapped_column(String(10))
    level: Mapped[int] = mapped_column(Integer, default=1)
    stamina: Mapped[int] = mapped_column(Integer, default=100)
    stamina_max: Mapped[int] = mapped_column(Integer, default=100)
    money: Mapped[int] = mapped_column(Integer, default=0)
    tickets: Mapped[int] = mapped_column(Integer, default=0)
    kanojo_count: Mapped[int] = mapped_column(Integer, default=0)
    generate_count: Mapped[int] = mapped_column(Integer, default=0)
    scan_count: Mapped[int] = mapped_column(Integer, default=0)
    enemy_count: Mapped[int] = mapped_column(Integer, default=0)
    wish_count: Mapped[int] = mapped_column(Integer, default=0)
    profile_image_url: Mapped[str | None] = mapped_column(String(255))
    device_token: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_api_dict(self) -> dict:
        """Serialize to JSON matching the Android KanojoParser/UserParser field names."""
        return {
            "id": self.id,
            "name": self.name or "",
            "email": self.email or "",
            "birth_year": self.birth_year,
            "birth_month": self.birth_month,
            "birth_day": self.birth_day,
            "sex": self.sex or "",
            "language": self.language or "",
            "level": self.level,
            "stamina": self.stamina,
            "stamina_max": self.stamina_max,
            "money": self.money,
            "tickets": self.tickets,
            "kanojo_count": self.kanojo_count,
            "generate_count": self.generate_count,
            "scan_count": self.scan_count,
            "enemy_count": self.enemy_count,
            "wish_count": self.wish_count,
            "profile_image_url": self.profile_image_url or "",
        }
