from fastapi import APIRouter, HTTPException, Query
from typing import Dict, Any
from app.services.weather_service import WeatherService

router = APIRouter()

@router.get("/", response_model=Dict[str, Any])
async def get_weather(
    lat: float = Query(..., description="Bulunulan konumun enlemi (Latitude)"),
    lon: float = Query(..., description="Bulunulan konumun boylamı (Longitude)")
):
    """
    Belirtilen enlem ve boylam için anlık hava durumunu döndürür.
    """
    try:
        weather_data = await WeatherService.get_weather_by_location(lat=lat, lon=lon)
        return weather_data
    except Exception as e:
        if isinstance(e, HTTPException):
            raise
        raise HTTPException(status_code=500, detail=str(e))
