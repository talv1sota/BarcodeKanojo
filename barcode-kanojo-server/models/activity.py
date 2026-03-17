from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Activity(Base):
    __tablename__ = "activities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    activity_type: Mapped[int] = mapped_column(Integer, nullable=False)
    user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"))
    other_user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"))
    kanojo_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("kanojos.id"))
    product_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("products.id"))
    activity: Mapped[str | None] = mapped_column(String(1000))
    created_timestamp: Mapped[int | None] = mapped_column(Integer)

    def to_api_dict(self) -> dict:
        return {
            "id": self.id,
            "activity_type": self.activity_type,
            "user_id": self.user_id,
            "other_user_id": self.other_user_id,
            "kanojo_id": self.kanojo_id,
            "product_id": self.product_id,
            "activity": self.activity or "",
            "created_timestamp": self.created_timestamp or 0,
        }


class ScanHistory(Base):
    __tablename__ = "scan_histories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"))
    barcode: Mapped[str | None] = mapped_column(String(50))
    total_count: Mapped[int] = mapped_column(Integer, default=0)
    kanojo_count: Mapped[int] = mapped_column(Integer, default=0)
    friend_count: Mapped[int] = mapped_column(Integer, default=0)
    scanned_at: Mapped[int | None] = mapped_column(Integer)

    def to_api_dict(self) -> dict:
        return {
            "id": self.id,
            "barcode": self.barcode or "",
            "total_count": self.total_count,
            "kanojo_count": self.kanojo_count,
            "friend_count": self.friend_count,
        }


class KanojoVote(Base):
    __tablename__ = "kanojo_votes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    kanojo_id: Mapped[int] = mapped_column(Integer, ForeignKey("kanojos.id"), nullable=False)
    voted_like: Mapped[bool] = mapped_column(default=False)


class UserKanojoRelation(Base):
    __tablename__ = "user_kanojo_relations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    kanojo_id: Mapped[int] = mapped_column(Integer, ForeignKey("kanojos.id"), nullable=False)
    relation_status: Mapped[int] = mapped_column(Integer, default=1)
    love_gauge: Mapped[int] = mapped_column(Integer, default=0)
