import pandas as pd
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


ddi_service = DDIService()
