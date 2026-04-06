from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.ddi_service import ddi_service
from app.services.gemini_service import gemini_service
from app.api.v1.schemas import DDIInteraction, DDIResponse, DDIExplainRequest, DDIExplainResponse

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


@router.post("/explain", response_model=DDIExplainResponse)
def explain_ddi(request: DDIExplainRequest):
    """
    Kısa etkileşim açıklamasını alıp Gemini üzerinden doktor için detaylı açıklama metni döner.
    """
    prompt = (
        f"You are an expert pharmacologist.\n"
        f"Please explain the interaction between the following two active ingredients to a doctor in a clinical and professional tone.\n\n"
        f"Active Ingredient 1: {request.active_ingredient_1}\n"
        f"Active Ingredient 2: {request.active_ingredient_2}\n"
        f"Short Interaction Description: {request.description}\n\n"
        f"In your explanation, briefly include the potential mechanism, what the doctor should watch out for, "
        f"and any actionable dosage or clinical monitoring recommendations. Write the entire response in English."
    )
    
    explanation = gemini_service.generate_text(prompt)
    return DDIExplainResponse(explanation=explanation)
