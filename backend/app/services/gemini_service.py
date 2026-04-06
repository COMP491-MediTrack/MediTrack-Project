import google.generativeai as genai
from fastapi import HTTPException
from app.core.config import settings

class GeminiService:
    def generate_text(self, prompt: str) -> str:
        if not settings.gemini_api_key:
            raise HTTPException(status_code=500, detail="GEMINI_API_KEY is not configured in .env")
        
        genai.configure(api_key=settings.gemini_api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        try:
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Gemini API error: {str(e)}")

gemini_service = GeminiService()
