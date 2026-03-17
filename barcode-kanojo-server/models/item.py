from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Item(Base):
    """Catalog of items available for purchase/use (gifts, dates, tickets)."""
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    item_class: Mapped[int] = mapped_column(Integer, nullable=False)  # 1=gift, 2=date, 3=ticket
    item_category_id: Mapped[int | None] = mapped_column(Integer)
    title: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(String(1000))
    image_thumbnail_url: Mapped[str | None] = mapped_column(String(255))
    image_url: Mapped[str | None] = mapped_column(String(255))
    price: Mapped[str | None] = mapped_column(String(50))
    confirm_purchase_message: Mapped[str | None] = mapped_column(String(1000))
    confirm_use_message: Mapped[str | None] = mapped_column(String(1000))
    purchasable_level: Mapped[str | None] = mapped_column(String(50))
    purchase_product_id: Mapped[str | None] = mapped_column(String(100))
    time_of_day: Mapped[int] = mapped_column(Integer, default=0)  # 0=any, 1=morn, 2=noon, 3=eve, 4=night

    def to_api_dict(self) -> dict:
        return {
            "item_id": self.id,
            "item_class": self.item_class,
            "item_category_id": self.item_category_id or 0,
            "title": self.title or "",
            "description": self.description or "",
            "image_thumbnail_url": self.image_thumbnail_url or "",
            "image_url": self.image_url or "",
            "price": self.price or "",
            "confirm_purchase_message": self.confirm_purchase_message or "",
            "confirm_use_message": self.confirm_use_message or "",
            "purchasable_level": self.purchasable_level or "",
            "purchase_product_id": self.purchase_product_id or "",
            "category": False,
            "expand_flag": 0,
        }


class UserItem(Base):
    """Items owned by a user."""
    __tablename__ = "user_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id"), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=0)
