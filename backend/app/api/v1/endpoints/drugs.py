from fastapi import APIRouter, HTTPException, Query
from app.services.drug_service import drug_service
from app.api.v1.schemas import DrugResponse, DrugSearchResponse

router = APIRouter()


@router.get("/search", response_model=DrugSearchResponse)
def search_drug(name: str = Query(..., min_length=2)):
    results = drug_service.search_by_name(name)
    if not results:
        raise HTTPException(status_code=404, detail="No drugs found")
    return DrugSearchResponse(results=[DrugResponse(**r) for r in results])


@router.get("/barcode", response_model=DrugResponse)
def search_by_barcode(code: str = Query(...)):
    result = drug_service.search_by_barcode(code)
    if not result:
        raise HTTPException(status_code=404, detail="Drug not found")
    return DrugResponse(**result)
