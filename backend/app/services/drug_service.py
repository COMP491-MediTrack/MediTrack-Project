import csv
import re
import pandas as pd
from app.core.config import settings

# Barkod pattern: 13 haneli rakam (Türkiye ilaç barkodları 869 ile başlar)
_BARCODE_RE = re.compile(r'^\d{13}$')


def _parse_turkish_drugs_csv(path: str) -> pd.DataFrame:
    """
    CSV'de ilaç isimlerinde ondalık virgül var (ör: "CAMZYOS 2,5 MG").
    Barkod kolonunu (13 haneli sayı) anchor olarak kullanarak
    satırları doğru parse eder.
    """
    rows = []
    with open(path, encoding="utf-8") as f:
        reader = csv.reader(f)
        for raw in reader:
            # Barkod kolonunu bul (13 haneli sayı)
            barcode_idx = next(
                (i for i, v in enumerate(raw) if _BARCODE_RE.match(v.strip())),
                None,
            )
            if barcode_idx is None:
                continue
            brand_name = ",".join(raw[:barcode_idx]).strip()
            rest = raw[barcode_idx:]
            if len(rest) < 4:
                continue
            rows.append({
                "brand_name": brand_name.upper(),
                "barcode": rest[0].strip(),
                "atc_code": rest[1].strip() if len(rest) > 1 else "",
                "generic_name": rest[2].strip().lower() if len(rest) > 2 else "",
                "manufacturer": rest[3].strip() if len(rest) > 3 else "",
            })
    return pd.DataFrame(rows)


class DrugService:
    def __init__(self):
        self._df: pd.DataFrame | None = None

    def _load(self):
        if self._df is None:
            self._df = _parse_turkish_drugs_csv(settings.turkish_drugs_csv)

    def search_by_name(self, name: str) -> list[dict]:
        self._load()
        query = name.strip().upper()
        results = self._df[self._df["brand_name"].str.contains(query, na=False)]
        return self._to_list(results)

    def search_by_barcode(self, barcode: str) -> dict | None:
        self._load()
        result = self._df[self._df["barcode"] == barcode.strip()]
        if result.empty:
            return None
        row = result.iloc[0]
        return {
            "brand_name": row["brand_name"],
            "barcode": row["barcode"],
            "generic_name": row["generic_name"],
            "atc_code": row["atc_code"],
            "manufacturer": row["manufacturer"],
        }

    def get_generic_name(self, brand_name: str) -> str | None:
        self._load()
        query = brand_name.strip().upper()
        result = self._df[self._df["brand_name"].str.startswith(query, na=False)]
        if result.empty:
            return None
        return result.iloc[0]["generic_name"]

    def _to_list(self, df: pd.DataFrame) -> list[dict]:
        return [
            {
                "brand_name": row["brand_name"],
                "barcode": row["barcode"],
                "generic_name": row["generic_name"],
                "atc_code": row["atc_code"],
                "manufacturer": row["manufacturer"],
            }
            for _, row in df.iterrows()
        ]


drug_service = DrugService()
