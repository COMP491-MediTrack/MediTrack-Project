# MediTrack — CLAUDE.md

> **Not:** Commit mesajlarına asla `Co-Authored-By: Claude` ekleme. Claude contributor olarak görünmemeli.

Koç Üniversitesi COMP491 bitirme projesi. Reçete ve ilaç takip uygulaması.
Hedef: Doktor ve hasta rollerine sahip, mobil + web platformlarda çalışan dijital sağlık yönetim sistemi.

---

## Proje Yapısı

```
MediTrack-Project/
├── frontend/   # Flutter uygulaması (iOS, Android, Web)
└── backend/    # Python FastAPI servisi (sadece ilaç verisi)
```

---

## Mimari Karar — Hangi Servis Ne Yapar

```
Flutter → Firebase Auth       # Login, register, token
Flutter → Firestore           # Reçete, reminder, adherence, profil, lab sonuçları
Flutter → FastAPI             # İlaç arama, barkod, DDI kontrolü
FastAPI → CSV                 # Türk ilaç DB (7,917 ilaç) + DDI DB (191,542 kayıt)
FastAPI → OpenFDA API         # Generic name bazlı ek ilaç bilgisi (eklenecek)
```

**Firebase Firestore koleksiyonları:**
- `users` — kullanıcı profilleri (rol: doctor | patient)
- `prescriptions` — reçeteler
- `reminders` — ilaç hatırlatıcıları
- `adherence` — ilaç alım kayıtları
- `lab_results` — laboratuvar sonuçları (PDF, Firebase Storage)

---

## Flutter — Mimari

**Pattern:** Clean Architecture + Feature-Layered

Her feature şu katmanlara sahiptir:
```
features/{feature_name}/
├── data/
│   ├── datasources/     # Remote (Dio/Firebase) ve local (Hive) kaynaklar
│   ├── models/          # JSON serialize/deserialize, Entity'ye map
│   └── repositories/    # Repository implementasyonu
├── domain/
│   ├── entities/        # Saf Dart sınıfları, framework bağımsız
│   ├── repositories/    # Abstract repository interface'leri
│   └── usecases/        # Tek iş yapan use case sınıfları
└── presentation/
    ├── cubit/           # State yönetimi (Cubit veya Bloc)
    ├── pages/           # Ekranlar
    └── widgets/         # Ekrana özel widget'lar
```

**Mevcut feature'lar:**
- `auth` — Firebase Auth ile giriş/kayıt, rol yönetimi
- `prescription` — Doktor reçete oluşturur, hastaya atar
- `ddi` — İlaç-ilaç etkileşim kontrolü (FastAPI'ye gider)
- `drug_search` — İsim/barkod ile ilaç arama (FastAPI'ye gider)
- `medication` — Hasta ilaç takibi, hatırlatıcı, adherence streak
- `pharmacy` — Yakın eczane haritası
- `profile` — Kullanıcı profili, lab sonuçları

**core/ yapısı:**
```
core/
├── constants/   # AppConstants (apiBaseUrl, Firestore koleksiyon isimleri, roller)
├── di/          # GetIt + injectable dependency injection
├── errors/      # Failure sınıfları (ServerFailure, NetworkFailure, AuthFailure, CacheFailure)
├── network/     # Dio client, interceptor'lar (Firebase JWT header eklenir)
├── router/      # GoRouter config, route isimleri
├── theme/       # AppTheme, AppColors, AppTypography, AppSpacing
└── utils/       # Yardımcı fonksiyonlar
```

---

## Flutter — Paketler ve Kullanım Amaçları

| Paket | Amaç |
|---|---|
| `flutter_bloc` | State management (Cubit sade, Bloc karmaşık event'ler için) |
| `go_router` | Navigation, rol bazlı route yönlendirme |
| `get_it` + `injectable` | Dependency injection (injectable kod üretir) |
| `dio` | HTTP client, FastAPI çağrıları |
| `firebase_auth` | Kullanıcı girişi/kaydı |
| `cloud_firestore` | Uygulama verisi (reçete, reminder, adherence) |
| `firebase_storage` | Lab sonuçları PDF yükleme |
| `shared_preferences` | Token, dil, ayarlar (basit key-value) |
| `hive` | Yapısal cache (ilaç listesi, kullanıcı profili) |
| `dartz` | `Either<Failure, Success>` error handling |
| `equatable` | Value equality (entity ve state sınıfları için) |
| `flutter_screenutil` | Pixel perfect responsive layout |

**Henüz eklenmeyen paketler (eklenecek):**
- `hive_flutter` + `hive_generator` + `build_runner`
- `injectable` + `injectable_generator`
- `flutter_screenutil`

---

## Flutter — Error Handling Kuralı

`dartz` paketi ile `Either<Failure, Success>` pattern kullanılır:

```
Repository  →  Either<Failure, Entity>
UseCase     →  Either<Failure, Entity>
Cubit       →  emit(ErrorState(failure.message)) veya emit(SuccessState(data))
```

Tüm Failure tipleri `core/errors/failures.dart` içindedir:
- `ServerFailure` — API hatası
- `NetworkFailure` — Bağlantı yok
- `AuthFailure` — Firebase auth hatası
- `CacheFailure` — Local storage hatası

---

## Flutter — State Management Kuralı

- **Cubit** → Basit ekranlar (form, liste, profil)
- **Bloc** → Karmaşık event akışları (çok adımlı reçete oluşturma, DDI kontrol akışı)

State sınıfları `Equatable` extend eder.

---

## Flutter — Responsive Layout Kuralı

`flutter_screenutil` kullanılır. Tüm boyutlar `.w`, `.h`, `.sp`, `.r` ile verilir.
`ScreenUtil.init()` uygulama başında çalıştırılır.
Tasarım referans boyutu: 390x844 (iPhone 14 standartı).

---

## Flutter — DI Kuralı

`injectable` annotation'ları kullanılır:
- `@lazySingleton` — Repository, DataSource, UseCase
- `@injectable` — Cubit/Bloc (her seferinde yeni instance)

`injection.dart` içinde sadece `configureDependencies()` çağrılır, elle kayıt yapılmaz.

---

## Flutter — Network Katmanı Kuralı

`core/network/` altında Dio instance ve interceptor'lar tanımlanır:
- Firebase Auth token her istekte header'a otomatik eklenir
- 401 gelirse kullanıcı login'e yönlendirilir
- Timeout, base URL `AppConstants.apiBaseUrl` üzerinden gelir

---

## MVP (Önce Bunlar Bitmeli)

1. Auth — Firebase login/register, rol bazlı yönlendirme (doctor/patient)
2. Doctor Dashboard — Reçete oluştur, hastaya ata, DDI kontrolü
3. Patient Dashboard — Aktif reçeteleri gör, ilacı aldım işaretle
4. DDI Modülü — Reçete yazılırken otomatik kontrol, uyarı göster
5. İlaç Arama — İsim veya barkod ile arama

## Secondary (MVP Sonrası)

6. Barkod tarama (kamera)
7. Hasta profili + lab sonuçları (PDF)
8. Randevu sistemi
9. Yakın eczane haritası
10. Adherence streak takibi
11. Erişilebilirlik (büyük font, text-to-speech)

---

## Backend (FastAPI) — Mimari

```
backend-fastapi/
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
└── data/
    ├── turkish_drugs.csv     # 7,917 Türk ilacı (brand name, barcode, generic name, ATC)
    └── db_drug_interactions.csv  # 191,542 DDI kaydı (drug1, drug2, description)
```

**Mevcut endpoint'ler:**
- `GET  /api/v1/health` — sağlık kontrolü
- `GET  /api/v1/drugs/search?name=` — isme göre arama
- `GET  /api/v1/drugs/barcode?code=` — barkod ile arama
- `POST /api/v1/ddi/check` — `{"drugs": ["warfarin", "aspirin"]}` → etkileşimler

**DDI akışı:**
1. Doktor reçeteye ilaç ekler (Türkçe brand name)
2. Flutter → FastAPI `/drugs/search` → generic name alır
3. Flutter → FastAPI `/ddi/check` → etkileşim sonuçlarını alır
4. Flutter uyarıyı doktora gösterir

## Backend — Eksikler (Eklenecek)

1. **Firebase JWT middleware** — Endpoint'ler şu an açık, token doğrulama yok
2. **Pydantic response modelleri** — Tip güvenli API contract
3. **OpenFDA entegrasyonu** — `GET /drugs/{generic_name}/info` endpoint'i
4. **Docker Compose** — backend + deploy için
5. **CORS kısıtlaması** — `allow_origins=["*"]` production'da kısıtlanacak

---

## Önemli Notlar

- FastAPI **kullanıcı verisi tutmaz**, sadece ilaç sorgulaması yapar
- Tüm uygulama verisi **Firestore**'da durur
- `data/` klasörü `.gitignore`'da, CSV'ler repoya commit edilmez
- İki kullanıcı rolü vardır: `doctor` ve `patient` — tüm UI bu role göre şekillenir
- Uygulama kendi başına tıbbi tavsiye vermez, sadece resmi veri kaynaklarından bilgi sunar
