# MediTrack — Backend (FastAPI)

Python tabanlı ilaç arama ve ilaç-ilaç etkileşimi (DDI) servisi.

> **Not:** Bu servis kullanıcı verisi **tutmaz**. Sadece ilaç sorgularını yanıtlar.
> Tüm uygulama verisi (reçete, reminder, profil) Firestore'dadır.

---

## Canlı Backend

Backend Render'da deploy edilmiştir, ekip üyelerinin herhangi bir kurulum yapmasına gerek yoktur.

```
https://meditrack-project-6io1.onrender.com
```

Flutter uygulaması bu adrese otomatik bağlanır.

---

## Yerel Geliştirme (isteğe bağlı)

Backend kodunu değiştirmek isteyenler için:

### Gereksinimler

- Python 3.11+
- pip

### Kurulum

```bash
cd MediTrack-Project/backend
python -m venv .venv

# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate

pip install -r requirements.txt
```

### Çalıştırma

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
├── data/                     # CSV dosyaları (repoda mevcut)
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

---

## Canlı Deploy

Backend Render'da deploy edilmiştir:

```
https://meditrack-project-6io1.onrender.com
```

> UptimeRobot ile her 5 dakikada bir ping atılıyor, spin down olmaz.
