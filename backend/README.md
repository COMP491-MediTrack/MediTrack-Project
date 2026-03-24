# MediTrack — Backend (FastAPI)

Python tabanlı ilaç arama ve ilaç-ilaç etkileşimi (DDI) servisi.

> **Not:** Bu servis kullanıcı verisi **tutmaz**. Sadece ilaç sorgularını yanıtlar.
> Tüm uygulama verisi (reçete, reminder, profil) Firestore'dadır.

---

## Gereksinimler

- Python 3.10+
- pip

---

## Kurulum

### 1. Repoyu klonla

```bash
git clone <repo-url>
cd MediTrack-Project/backend
```

### 2. Sanal ortam oluştur ve aktive et

```bash
python -m venv .venv

# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

### 3. Bağımlılıkları yükle

```bash
pip install -r requirements.txt
```

### 4. CSV data dosyalarını koy ⚠️

`data/` klasörü `.gitignore`'da olduğu için repoda **yoktur**.
Bu dosyaları proje grubundan alıp `backend/data/` klasörüne koyman gerekiyor:

```
backend/
└── data/
    ├── turkish_drugs.csv        # 7,917 Türk ilacı
    └── db_drug_interactions.csv # 191,542 DDI kaydı
```

> Dosyaları almak için grup WhatsApp/Drive'ına bak.

### 5. `.env` dosyasını oluştur

```bash
cp .env.example .env
```

Varsayılan ayarlar çalışır, değiştirmene gerek yok.

---

## Çalıştırma

```bash
uvicorn app.main:app --reload
```

Sunucu `http://localhost:8000` adresinde başlar.

---

## API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/v1/health` | Servis sağlık kontrolü |
| `GET` | `/api/v1/drugs/search?name=aspirin` | İsme göre ilaç arama |
| `GET` | `/api/v1/drugs/barcode?code=8699514090084` | Barkoda göre ilaç arama |
| `POST` | `/api/v1/ddi/check` | İlaç-ilaç etkileşim kontrolü |

### DDI Kontrol Örneği

```bash
curl -X POST http://localhost:8000/api/v1/ddi/check \
  -H "Content-Type: application/json" \
  -d '{"drugs": ["warfarin", "aspirin"]}'
```

---

## Proje Yapısı

```
backend/
├── app/
│   ├── main.py               # FastAPI app, CORS, router
│   ├── core/
│   │   └── config.py         # Pydantic settings (.env'den okur)
│   ├── api/v1/
│   │   ├── router.py         # Tüm router'ları toplar
│   │   └── endpoints/
│   │       ├── health.py
│   │       ├── drugs.py      # /search, /barcode
│   │       └── ddi.py        # /check
│   └── services/
│       ├── drug_service.py   # CSV'den ilaç arama/barkod
│       └── ddi_service.py    # CSV'den DDI kontrolü
├── data/                     # ⚠️ .gitignore'da — CSV'leri buraya koy
├── .env.example              # Örnek ortam değişkenleri
├── .gitignore
└── requirements.txt
```

---

## Swagger UI

Sunucu çalışırken tarayıcıdan tüm endpoint'leri test edebilirsin:

```
http://localhost:8000/docs
```
