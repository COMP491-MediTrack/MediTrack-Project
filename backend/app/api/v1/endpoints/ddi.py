from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.ddi_service import ddi_service
from app.api.v1.schemas import DDIInteraction, DDIResponse

router = APIRouter()


class DDIRequest(BaseModel):
    drugs: list[str]


@router.post("/check", response_model=DDIResponse)
def check_ddi(request: DDIRequest):
    if len(request.drugs) < 2:
        raise HTTPException(status_code=400, detail="At least 2 drugs required")
    interactions = ddi_service.check_interactions(request.drugs)
    return DDIResponse(
        drugs=request.drugs,
        interactions=[DDIInteraction(**i) for i in interactions],
        has_interactions=len(interactions) > 0,
    )
