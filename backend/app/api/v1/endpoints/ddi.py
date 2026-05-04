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
        "TASK: Provide a technical clinical explanation of the drug interaction below for a medical database. "
        "The output must be a direct, raw paragraph of information.\n\n"
        "CRITICAL - FORBIDDEN CONTENT:\n"
        "- DO NOT include ANY greetings (e.g., NEVER start with 'Dear Doctor', 'Hello', or 'Hi').\n"
        "- DO NOT include introductions or meta-talk (e.g., 'As an expert...', 'This interaction involves...').\n"
        "- DO NOT include closing remarks or signatures.\n\n"
        "REQUIREMENTS:\n"
        "- Format: Single concise paragraph.\n"
        "- Length: 4-6 sentences.\n"
        "- Content: Clinical mechanism, risks, and monitoring/dosage advice.\n"
        "- Tone: Professional and clinical.\n\n"
        f"Active Ingredient 1: {request.active_ingredient_1}\n"
        f"Active Ingredient 2: {request.active_ingredient_2}\n"
        f"Interaction Context: {request.description}\n\n"
        "OUTPUT THE CLINICAL TEXT IMMEDIATELY (NO GREETINGS):"
    )
    
    explanation = gemini_service.generate_text(prompt)
    return DDIExplainResponse(explanation=explanation)
