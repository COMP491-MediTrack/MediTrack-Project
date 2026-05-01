from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any, Optional
import httpx
from app.services.pharmacy_service import PharmacyService

router = APIRouter()

@router.get("/debug-fetch")
async def debug_fetch(url: str = Query(...)):
    """Render sunucusundan verilen URL'e istek atar, status + ilk 500 karakteri döner."""
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "tr-TR,tr;q=0.9",
        "Referer": "https://www.eczaneler.gen.tr/",
    }
    async with httpx.AsyncClient(follow_redirects=True) as client:
        r = await client.get(url, headers=headers, timeout=12.0)
    return {"status": r.status_code, "preview": r.text[:500]}

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
