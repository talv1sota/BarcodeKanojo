from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings
from models.database import init_db
from api import account, barcode, kanojo, user, communication, activity, resource, message, shopping


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure required directories exist (important for fresh Docker volumes)
    (settings.UPLOAD_DIR / "profile_images" / "kanojo").mkdir(parents=True, exist_ok=True)
    (settings.UPLOAD_DIR / "profile_images" / "user").mkdir(parents=True, exist_ok=True)
    await init_db()
    yield


app = FastAPI(title="Barcode Kanojo Server", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files for images and assets
app.mount("/static", StaticFiles(directory=str(settings.UPLOAD_DIR)), name="static")
app.mount(
    "/profile_images",
    StaticFiles(directory=str(settings.UPLOAD_DIR / "profile_images")),
    name="profile_images",
)

# API routes
app.include_router(account.router, prefix="/api/account", tags=["Account"])
app.include_router(barcode.router, prefix="/api/barcode", tags=["Barcode"])
app.include_router(kanojo.router, prefix="/api/kanojo", tags=["Kanojo"])
app.include_router(user.router, tags=["User"])
app.include_router(communication.router, prefix="/api/communication", tags=["Communication"])
app.include_router(activity.router, tags=["Activity"])
app.include_router(resource.router, prefix="/api/resource", tags=["Resource"])
app.include_router(message.router, prefix="/api/message", tags=["Message"])
app.include_router(shopping.router, prefix="/api/shopping", tags=["Shopping"])


@app.get("/")
async def root():
    return {"status": "ok", "message": "Barcode Kanojo Server"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
