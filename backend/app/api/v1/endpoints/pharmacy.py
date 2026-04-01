from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any
from app.services.pharmacy_service import PharmacyService

router = APIRouter()

@router.get("/on-duty", response_model=List[Dict[str, Any]])
async def get_on_duty_pharmacies(city: str = Query(..., description="İl adı, örn: istanbul, ankara")):
    """
    Belirtilen ildeki nöbetçi eczaneleri döndürür.
    """
    try:
        pharmacies = await PharmacyService.get_on_duty_pharmacies(city)
        return pharmacies
    except ValueError:
        return []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
