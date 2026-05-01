from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
from app.services.pharmacy_service import PharmacyService

router = APIRouter()

@router.get("/on-duty", response_model=List[Dict[str, Any]])
async def get_on_duty_pharmacies(
    city: str = Query(..., description="İl adı, örn: istanbul, ankara"),
    district: Optional[str] = Query(None, description="İlçe adı, örn: besiktas, kadikoy"),
):
    """
    Belirtilen ildeki (ve varsa ilçedeki) nöbetçi eczaneleri döndürür.
    """
    try:
        pharmacies = await PharmacyService.get_on_duty_pharmacies(city, district=district)
        return pharmacies
    except ValueError as e:
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
