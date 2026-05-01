from fastapi import APIRouter
from app.api.v1.endpoints import health, drugs, ddi, weather

router = APIRouter()

router.include_router(health.router, prefix="/health", tags=["health"])
router.include_router(drugs.router, prefix="/drugs", tags=["drugs"])
router.include_router(ddi.router, prefix="/ddi", tags=["ddi"])
router.include_router(weather.router, prefix="/weather", tags=["weather"])
