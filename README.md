# MediTrack

Koç Üniversitesi COMP491 bitirme projesi.
Reçete ve ilaç takip uygulaması — doktor, hasta ve laboratuvar rollerine sahip dijital sağlık yönetim sistemi.

---

## Proje Yapısı

```
MediTrack-Project/
├── frontend/   # Flutter uygulaması (iOS, Android, Web)
└── backend/    # Python FastAPI servisi (ilaç verisi + AI)
```

Detaylı kurulum ve mimari bilgisi için ilgili README'ye bakın:

- **Flutter kurulumu, mimari, paketler** → [frontend/README.md](./frontend/README.md)
- **FastAPI kurulumu, endpoint'ler, ortam değişkenleri** → [backend/README.md](./backend/README.md)

---

## Teknoloji Stack

```
Flutter  →  Firebase Auth       # Kimlik doğrulama
Flutter  →  Firestore           # Reçete, profil, uygulama verisi
Flutter  →  FastAPI             # İlaç arama, DDI kontrolü, AI
FastAPI  →  Claude API          # Semptom analizi, reçete özeti, lab analizi
FastAPI  →  CSV                 # 7,917 Türk ilacı + 191,542 DDI kaydı
```

---

## Canlı Backend

```
https://meditrack-project-6io1.onrender.com
```

| Endpoint | Açıklama |
|----------|----------|
| `GET /api/v1/health` | Servis sağlık kontrolü |
| `GET /api/v1/drugs/search?name=` | İlaç arama |
| `GET /api/v1/drugs/barcode?code=` | Barkod ile ilaç arama |
| `POST /api/v1/ddi/check` | İlaç-ilaç etkileşim kontrolü |

---

## Geliştirme

- Flutter kurulumu için → [frontend/README.md](./frontend/README.md)
- FastAPI kurulumu için → [backend/README.md](./backend/README.md)
