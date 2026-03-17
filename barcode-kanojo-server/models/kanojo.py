from datetime import datetime

from sqlalchemy import Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Kanojo(Base):
    __tablename__ = "kanojos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str | None] = mapped_column(String(100))
    barcode: Mapped[str] = mapped_column(String(50), nullable=False)
    owner_user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"))

    # Location
    geo_lat: Mapped[float] = mapped_column(Float, default=0.0)
    geo_lng: Mapped[float] = mapped_column(Float, default=0.0)
    location: Mapped[str | None] = mapped_column(String(255))
    nationality: Mapped[str | None] = mapped_column(String(255))

    # Birthday
    birth_year: Mapped[int] = mapped_column(Integer, default=2000)
    birth_month: Mapped[int] = mapped_column(Integer, default=1)
    birth_day: Mapped[int] = mapped_column(Integer, default=1)

    # Appearance — 14 part types (matching KanojoParser JSON fields)
    race_type: Mapped[int] = mapped_column(Integer, default=1)
    eye_type: Mapped[int] = mapped_column(Integer, default=1)
    nose_type: Mapped[int] = mapped_column(Integer, default=1)
    mouth_type: Mapped[int] = mapped_column(Integer, default=1)
    face_type: Mapped[int] = mapped_column(Integer, default=1)
    brow_type: Mapped[int] = mapped_column(Integer, default=1)
    fringe_type: Mapped[int] = mapped_column(Integer, default=1)
    hair_type: Mapped[int] = mapped_column(Integer, default=1)
    accessory_type: Mapped[int] = mapped_column(Integer, default=0)
    spot_type: Mapped[int] = mapped_column(Integer, default=0)
    glasses_type: Mapped[int] = mapped_column(Integer, default=0)
    body_type: Mapped[int] = mapped_column(Integer, default=1)
    clothes_type: Mapped[int] = mapped_column(Integer, default=1)
    ear_type: Mapped[int] = mapped_column(Integer, default=0)

    # Colors
    skin_color: Mapped[int] = mapped_column(Integer, default=1)
    hair_color: Mapped[int] = mapped_column(Integer, default=1)
    eye_color: Mapped[int] = mapped_column(Integer, default=1)

    # Feature positions
    eye_position: Mapped[float] = mapped_column(Float, default=0.0)
    brow_position: Mapped[float] = mapped_column(Float, default=0.0)
    mouth_position: Mapped[float] = mapped_column(Float, default=0.0)

    # Stats (radar chart)
    flirtable: Mapped[int] = mapped_column(Integer, default=50)
    consumption: Mapped[int] = mapped_column(Integer, default=50)
    possession: Mapped[int] = mapped_column(Integer, default=50)
    recognition: Mapped[int] = mapped_column(Integer, default=50)
    sexual: Mapped[int] = mapped_column(Integer, default=50)

    # Relationship
    love_gauge: Mapped[int] = mapped_column(Integer, default=75)
    follower_count: Mapped[int] = mapped_column(Integer, default=0)
    like_rate: Mapped[int] = mapped_column(Integer, default=0)
    relation_status: Mapped[int] = mapped_column(Integer, default=1)  # 1=other, 2=kanojo, 3=friend
    emotion_status: Mapped[int] = mapped_column(Integer, default=0)
    mascot_enabled: Mapped[int] = mapped_column(Integer, default=0)

    # State
    status: Mapped[str | None] = mapped_column(String(255))
    in_room: Mapped[bool] = mapped_column(Boolean, default=True)
    on_date: Mapped[bool] = mapped_column(Boolean, default=False)
    date_location: Mapped[str | None] = mapped_column(String(255))

    # Profile images (server-generated)
    profile_image_url: Mapped[str | None] = mapped_column(String(255))

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_api_dict(self) -> dict:
        """Serialize to JSON matching Android KanojoParser field names."""
        return {
            "id": self.id,
            "name": self.name or "",
            "barcode": self.barcode,
            "owner_user_id": self.owner_user_id,
            "geo": {"lat": self.geo_lat, "lng": self.geo_lng} if self.geo_lat or self.geo_lng else None,
            "location": self.location or "",
            "nationality": self.nationality or "",
            "birth_year": self.birth_year,
            "birth_month": self.birth_month,
            "birth_day": self.birth_day,
            "race_type": self.race_type,
            "eye_type": self.eye_type,
            "nose_type": self.nose_type,
            "mouth_type": self.mouth_type,
            "face_type": self.face_type,
            "brow_type": self.brow_type,
            "fringe_type": self.fringe_type,
            "hair_type": self.hair_type,
            "accessory_type": self.accessory_type,
            "spot_type": self.spot_type,
            "glasses_type": self.glasses_type,
            "body_type": self.body_type,
            "clothes_type": self.clothes_type,
            "ear_type": self.ear_type,
            "skin_color": self.skin_color,
            "hair_color": self.hair_color,
            "eye_color": self.eye_color,
            "eye_position": self.eye_position,
            "brow_position": self.brow_position,
            "mouth_position": self.mouth_position,
            "flirtable": self.flirtable,
            "consumption": self.consumption,
            "possession": self.possession,
            "recognition": self.recognition,
            "sexual": self.sexual,
            "love_gauge": self.love_gauge,
            "follower_count": self.follower_count,
            "like_rate": self.like_rate,
            "relation_status": self.relation_status,
            "emotion_status": self.emotion_status,
            "mascot_enabled": self.mascot_enabled,
            "status": self.status or "",
            "in_room": self.in_room,
            "on_date": self.on_date,
            "date_location": self.date_location or "",
            "profile_image_url": self.profile_image_url or "",
            "created_at": int(self.created_at.timestamp()) if self.created_at else 0,
        }
