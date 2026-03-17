from pydantic_settings import BaseSettings
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# Default avatar_data path: next to server in the iOS project
_DEFAULT_AVATAR_DATA = str(
    BASE_DIR.parent / "BarcodeKanojo-iOS" / "BarcodeKanojo" / "Resources" / "avatar_data"
)


class Settings(BaseSettings):
    DATABASE_URL: str = f"sqlite+aiosqlite:///{BASE_DIR}/barcode_kanojo.db"
    SECRET_KEY: str = "change-me-in-production"
    SESSION_EXPIRY_HOURS: int = 720  # 30 days
    UPLOAD_DIR: Path = BASE_DIR / "static"
    AVATAR_DATA_DIR: str = _DEFAULT_AVATAR_DATA
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    class Config:
        env_file = ".env"


settings = Settings()
