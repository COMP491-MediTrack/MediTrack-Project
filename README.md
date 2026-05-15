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

## Ana Özellikler ve İş Akışı

MediTrack, sağlık süreçlerini dijitalleştiren kapsamlı bir ekosistem sunar:

- **Doktor Paneli:** Hasta listesi takibi, ilaç etkileşim (DDI) kontrollü reçete yazımı ve tahlil isteği oluşturma.
- **Hasta Paneli:** Aktif reçetelerin takibi, ilaç hatırlatıcıları ve tahlil sonuçlarını görüntüleme.
- **Laboratuvar Entegrasyonu:** Tüm tahlil isteklerinin merkezi takibi ve sonuç (PDF) yükleme işlemleri.
- **Akıllı İş Akışı:** Laboratuvar görevlisi tarafından PDF yüklendiği anda, tahlil isteğinin statüsü otomatik olarak **"Bekliyor"** konumundan **"Tamamlandı"** konumuna güncellenir.
- **Entegre Veri Akışı:** Doktor tarafından oluşturulan tahlil istekleri anında laboratuvar paneline düşer ve sonuçlar yüklendiğinde hem doktor hem de hasta tarafından anlık olarak erişilebilir.

---

## Teknoloji Stack

```
Flutter  →  Firebase Auth       # Kimlik doğrulama
Flutter  →  Firestore           # Reçete, profil, uygulama verisi (Tahlil istekleri ve sonuç bağlamı)
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
