import pandas as pd
import google.generativeai as genai
from fastapi import HTTPException
from app.core.config import settings


class DDIService:
    def __init__(self):
        self._df: pd.DataFrame | None = None

    def _load(self):
        if self._df is None:
            self._df = pd.read_csv(settings.ddi_interactions_csv)
            self._df["Drug 1"] = self._df["Drug 1"].str.strip().str.lower()
            self._df["Drug 2"] = self._df["Drug 2"].str.strip().str.lower()

    def check_interactions(self, generic_names: list[str]) -> list[dict]:
        self._load()
        names = [n.strip().lower() for n in generic_names]
        results = []

        for i in range(len(names)):
            for j in range(i + 1, len(names)):
                drug1, drug2 = names[i], names[j]
                matches = self._df[
                    ((self._df["Drug 1"] == drug1) & (self._df["Drug 2"] == drug2)) |
                    ((self._df["Drug 1"] == drug2) & (self._df["Drug 2"] == drug1))
                ]
                for _, row in matches.iterrows():
                    results.append({
                        "drug1": drug1,
                        "drug2": drug2,
                        "description": row["Interaction Description"],
                    })

        return results

    def explain_interaction_to_doctor(self, active_ingredient_1: str, active_ingredient_2: str, short_desc: str) -> str:
        if not settings.gemini_api_key:
            raise HTTPException(status_code=500, detail="GEMINI_API_KEY is not configured in .env")
        
        genai.configure(api_key=settings.gemini_api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        prompt = (
            f"You are an expert pharmacologist.\n"
            f"Please explain the interaction between the following two active ingredients to a doctor in a clinical and professional tone.\n\n"
            f"Active Ingredient 1: {active_ingredient_1}\n"
            f"Active Ingredient 2: {active_ingredient_2}\n"
            f"Short Interaction Description: {short_desc}\n\n"
            f"In your explanation, briefly include the potential mechanism, what the doctor should watch out for, "
            f"and any actionable dosage or clinical monitoring recommendations. Write the entire response in English."
        )
        
        try:
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Gemini API error: {str(e)}")


ddi_service = DDIService()
