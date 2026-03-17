from datetime import datetime

from sqlalchemy import Integer, String, Float, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    barcode: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str | None] = mapped_column(String(255))
    company_name: Mapped[str | None] = mapped_column(String(255))
    category_id: Mapped[int] = mapped_column(Integer, default=1)
    category: Mapped[str | None] = mapped_column(String(100))
    comment: Mapped[str | None] = mapped_column(String(1000))
    geo_lat: Mapped[float] = mapped_column(Float, default=0.0)
    geo_lng: Mapped[float] = mapped_column(Float, default=0.0)
    location: Mapped[str | None] = mapped_column(String(255))
    country: Mapped[str | None] = mapped_column(String(100))
    price: Mapped[str | None] = mapped_column(String(50))
    product_image_url: Mapped[str | None] = mapped_column(String(255))
    scan_count: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    def to_api_dict(self) -> dict:
        return {
            "id": self.id,
            "barcode": self.barcode,
            "name": self.name or "",
            "company_name": self.company_name or "",
            "category_id": self.category_id,
            "category": self.category or "",
            "comment": self.comment or "",
            "geo": {"lat": self.geo_lat, "lng": self.geo_lng},
            "location": self.location or "",
            "country": self.country or "",
            "price": self.price or "",
            "product_image_url": self.product_image_url or "",
            "scan_count": self.scan_count,
        }


class ProductCategory(Base):
    __tablename__ = "product_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)

    def to_api_dict(self) -> dict:
        return {"id": self.id, "name": self.name}
