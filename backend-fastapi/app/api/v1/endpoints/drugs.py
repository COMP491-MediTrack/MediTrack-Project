from fastapi import APIRouter, HTTPException, Query
from app.services.drug_service import drug_service

router = APIRouter()


@router.get("/search")
def search_drug(name: str = Query(..., min_length=2)):
    results = drug_service.search_by_name(name)
    if not results:
        raise HTTPException(status_code=404, detail="No drugs found")
    return {"results": results}


@router.get("/barcode")
def search_by_barcode(code: str = Query(...)):
    result = drug_service.search_by_barcode(code)
    if not result:
        raise HTTPException(status_code=404, detail="Drug not found")
    return result
