from pydantic import BaseModel


class DrugResponse(BaseModel):
    brand_name: str
    barcode: str
    generic_name: str
    atc_code: str
    manufacturer: str


class DrugSearchResponse(BaseModel):
    results: list[DrugResponse]


class DDIInteraction(BaseModel):
    drug1: str
    drug2: str
    description: str


class DDIResponse(BaseModel):
    drugs: list[str]
    interactions: list[DDIInteraction]
    has_interactions: bool


class DDIExplainRequest(BaseModel):
    active_ingredient_1: str
    active_ingredient_2: str
    description: str


class DDIExplainResponse(BaseModel):
    explanation: str
