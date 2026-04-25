import httpx
from typing import Dict, Any
from fastapi import HTTPException
from app.core.config import settings

class WeatherService:
    BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

    @classmethod
    async def get_weather_by_location(cls, lat: float, lon: float) -> Dict[str, Any]:
        if not settings.weather_api:
            raise HTTPException(status_code=500, detail="Weather API key is not configured in .env")
        
        # Constructs the URL exactly as provided:
        # https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_Key}
        url = f"{cls.BASE_URL}?lat={lat}&lon={lon}&appid={settings.weather_api}&units=metric&lang=tr"
        
        async with httpx.AsyncClient() as client:
            try:
                # Make the GET request directly to the full URL string
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                
                return {
                    "temperature": data.get("main", {}).get("temp"),
                    "feels_like": data.get("main", {}).get("feels_like"),
                    "humidity": data.get("main", {}).get("humidity"),
                    "description": data.get("weather", [{}])[0].get("description"),
                    "weather_main": data.get("weather", [{}])[0].get("main"),
                    "city": data.get("name"),
                    "country": data.get("sys", {}).get("country"),
                    "wind_speed": data.get("wind", {}).get("speed"),
                    "raw": data # Keep raw data available just in case
                }
            except httpx.HTTPStatusError as e:
                raise HTTPException(
                    status_code=e.response.status_code, 
                    detail=f"Weather API error: {e.response.text}"
                )
            except Exception as e:
                raise HTTPException(
                    status_code=500, 
                    detail=f"Internal error getting weather: {str(e)}"
                )
