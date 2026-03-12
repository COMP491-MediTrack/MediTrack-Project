from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "MediTrack API"
    app_version: str = "1.0.0"
    debug: bool = True
    turkish_drugs_csv: str = "data/turkish_drugs.csv"
    ddi_interactions_csv: str = "data/db_drug_interactions.csv"

    class Config:
        env_file = ".env"


settings = Settings()
