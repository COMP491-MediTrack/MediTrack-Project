# MediTrack — CLAUDE.md

> **Not:** Commit mesajlarına asla `Co-Authored-By: Claude` ekleme. Claude contributor olarak görünmemeli.

Koç Üniversitesi COMP491 bitirme projesi. Reçete ve ilaç takip uygulaması.
Hedef: Doktor, hasta ve laboratuvar rollerine sahip, mobil + web platformlarda çalışan dijital sağlık yönetim sistemi.

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
Flutter → FastAPI             # İlaç arama, barkod, DDI kontrolü, AI endpoint'leri
FastAPI → CSV                 # Türk ilaç DB (7,917 ilaç) + DDI DB (191,542 kayıt)
FastAPI → Claude API          # AI: semptom analizi, reçete özeti, lab sonucu analizi
FastAPI → OpenFDA API         # Generic name bazlı ek ilaç bilgisi (eklenecek)
```

**Firebase Firestore koleksiyonları:**
- `users` — kullanıcı profilleri (rol: doctor | patient | lab, doctorId: hasta için bağlı doktor)
- `prescriptions` — reçeteler (doctorId, patientId, drugs[], status, createdAt)
- `reminders` — ilaç hatırlatıcıları
- `adherence` — ilaç alım kayıtları
- `lab_results` — laboratuvar sonuçları (PDF, Firebase Storage)
- `test_requests` — doktorun hastadan istediği tahliller (patient_id, patient_name, doctor_id, doctor_name, requested_tests[], status, created_at)

**Firestore Security Rules özeti:**
- Kullanıcı kendi dokümanını okuyup yazabilir
- Giriş yapmış herkes doktorları listeleyebilir (kayıt ekranı için)
- Doktor kendi hastalarını görebilir (doctorId == currentUser.uid)
- Hasta kendi doktorunun profilini okuyabilir
- Lab kullanıcısı tüm `test_requests` koleksiyonunu okuyabilir ve `lab_results` yazabilir

---

## Kullanıcı Rolleri ve Akışlar

**Doctor:**
- Kayıt olurken rol "Doktor" seçilir, doctorId alanı olmaz
- Dashboard: hasta listesi (Firestore'dan doctorId == uid sorgusu)
- Reçete yazar → FastAPI'ye ilaç arama → DDI kontrolü → Firestore'a kaydeder
- Hasta semptomlarını ve AI öncelik skorunu görür

**Patient:**
- Kayıt olurken rol "Hasta" seçilir ve listeden doktor seçilir
- Firestore'da `doctorId` alanı oluşturulur
- Dashboard: aktif reçeteler, ilacı aldım butonu
- Semptomlarını girer → AI analiz eder → doktora öncelik skoru gider

**Lab (Laboratuvar):**
- Kayıt olurken rol "Lab" seçilir, doctorId alanı olmaz
- Dashboard: tüm bekleyen ve tamamlanan tahlil istekleri
- Bekleyen istekler için lab sonucu PDF'i yükler (Firebase Storage → Firestore `lab_results`)
- Doktor veya hastayla bağlı değildir; tüm `test_requests` koleksiyonuna erişir

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

**Tamamlanan feature'lar:**
- `auth` — Firebase Auth ile giriş/kayıt, rol yönetimi (doctor | patient | lab), hasta→doktor seçimi
- `dashboard` — Doctor dashboard (hasta listesi), Patient dashboard (reçete özeti), Lab dashboard (tahlil istekleri)

**Yapılacak feature'lar:**
- `prescription` — Doktor reçete oluşturur, ilaç arar, DDI kontrolü, Firestore'a kaydeder
- `drug_search` — İsim/barkod ile FastAPI'den ilaç arama (prescription ile birlikte)
- `ddi` — Reçete yazılırken otomatik DDI kontrolü ve uyarı
- `ai` — Semptom analizi, reçete özeti, lab sonucu analizi (Claude API via FastAPI)
- `medication` — Hasta ilaç takibi, hatırlatıcı, adherence streak
- `pharmacy` — Yakın eczane haritası
- `profile` — Kullanıcı profili, lab sonuçları PDF

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
| `hive` + `hive_flutter` | Yapısal cache (ilaç listesi, kullanıcı profili) |
| `dartz` | `Either<Failure, Success>` error handling |
| `equatable` | Value equality (entity ve state sınıfları için) |
| `flutter_screenutil` | Pixel perfect responsive layout (referans: 390x844 iPhone 14) |

---

## Flutter — Kurallar

### Error Handling
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

### State Management
- **Cubit** → Basit ekranlar (form, liste, profil)
- **Bloc** → Karmaşık event akışları (çok adımlı reçete oluşturma, DDI kontrol akışı)
- State sınıfları `Equatable` extend eder

### Responsive Layout
- `flutter_screenutil` kullanılır
- Tüm boyutlar `.w`, `.h`, `.sp`, `.r` ile verilir
- `ScreenUtil.init()` uygulama başında çalıştırılır
- Tasarım referans boyutu: 390x844 (iPhone 14)

### Dependency Injection
- `@lazySingleton` — Repository, DataSource, UseCase
- `@injectable` — Cubit/Bloc (her seferinde yeni instance)
- `injection.dart` içinde sadece `configureDependencies()` çağrılır, elle kayıt yapılmaz
- Değişiklik sonrası `dart run build_runner build --delete-conflicting-outputs` çalıştır

### Network Katmanı
- `core/network/` altında Dio instance ve interceptor'lar tanımlanır
- Firebase Auth token her istekte header'a otomatik eklenir
- 401 gelirse kullanıcı login'e yönlendirilir
- Timeout, base URL `AppConstants.apiBaseUrl` üzerinden gelir

---

## MVP Durumu

| # | Feature | Durum |
|---|---------|-------|
| 1 | Auth (login/register/rol/doktor seçimi) | ✅ Tamamlandı |
| 2 | Doctor & Patient Dashboard | ✅ Tamamlandı |
| 3 | Prescription Feature | ✅ Tamamlandı |
| 4 | Drug Search (FastAPI entegrasyonu) | ✅ Tamamlandı |
| 5 | DDI Kontrolü | ✅ Tamamlandı |
| 6 | Lab Dashboard (tahlil istekleri + PDF yükleme) | ✅ Tamamlandı |

## Secondary (MVP Sonrası)

| # | Feature | Notlar |
|---|---------|--------|
| 7 | AI — Semptom analizi + doktor öncelik sıralaması | FastAPI → Claude API |
| 8 | AI — Reçete özeti (hasta için sade dil) | FastAPI → Claude API |
| 9 | AI — Lab sonucu PDF analizi | FastAPI → Claude API |
| 10 | Barkod tarama (kamera) | |
| 11 | Hasta profili + lab sonuçları (PDF) | Firebase Storage |
| 12 | Yakın eczane haritası | Google Maps API |
| 13 | Adherence streak takibi | |
| 14 | Erişilebilirlik (büyük font, text-to-speech) | |

---

## Backend (FastAPI) — Mimari

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
│   │       ├── ddi.py        # /check
│   │       └── ai.py         # /analyze-symptoms, /explain-prescription, /analyze-lab (eklenecek)
│   └── services/
│       ├── drug_service.py   # CSV'den ilaç arama/barkod
│       ├── ddi_service.py    # CSV'den DDI kontrolü
│       └── ai_service.py     # Claude API entegrasyonu (eklenecek)
└── data/
    ├── turkish_drugs.csv     # 7,917 Türk ilacı (brand name, barcode, generic name, ATC)
    └── db_drug_interactions.csv  # 191,542 DDI kaydı (drug1, drug2, description)
```

**Mevcut endpoint'ler:**
- `GET  /api/v1/health` — sağlık kontrolü
- `GET  /api/v1/drugs/search?name=` — isme göre arama
- `GET  /api/v1/drugs/barcode?code=` — barkod ile arama
- `POST /api/v1/ddi/check` — `{"drugs": ["warfarin", "aspirin"]}` → etkileşimler

**Eklenecek endpoint'ler:**
- `POST /api/v1/ai/analyze-symptoms` — semptom analizi → öncelik skoru
- `POST /api/v1/ai/explain-prescription` — reçete özeti (sade Türkçe)
- `POST /api/v1/ai/analyze-lab-result` — lab sonucu PDF analizi

**DDI akışı:**
1. Doktor reçeteye ilaç ekler (Türkçe brand name)
2. Flutter → FastAPI `/drugs/search` → generic name alır
3. Flutter → FastAPI `/ddi/check` → etkileşim sonuçlarını alır
4. Flutter uyarıyı doktora gösterir

**AI akışı:**
1. Hasta semptomlarını girer
2. Flutter → FastAPI `/ai/analyze-symptoms` → Claude API → öncelik skoru + açıklama
3. Firestore'daki hasta profiline kaydedilir
4. Doktor dashboard'unda hasta öncelik sırasına göre listelenir

## Backend — Yapılacaklar

1. **Firebase JWT middleware** — Endpoint'ler şu an açık, token doğrulama yok
2. **Pydantic response modelleri** — Tip güvenli API contract
3. **Docker + docker-compose** — Ekip ve hoca için kolay kurulum
4. **AI endpoint'leri** — Claude API entegrasyonu
5. **OpenFDA entegrasyonu** — `GET /drugs/{generic_name}/info`
6. **CORS kısıtlaması** — `allow_origins=["*"]` production'da kısıtlanacak

---

## Önemli Notlar

- FastAPI **kullanıcı verisi tutmaz**, sadece ilaç sorgulaması ve AI işlemleri yapar
- Tüm uygulama verisi **Firestore**'da durur
- `data/` klasörü `.gitignore`'da, CSV'ler repoya commit edilmez
- Üç kullanıcı rolü: `doctor`, `patient` ve `lab` — tüm UI bu role göre şekillenir
- Hasta kayıt olurken Firestore'daki doktorlar listelenir, bir doktor seçmek zorundadır
- Lab kayıt olurken doktor seçimi gerekmez; `doctorId` alanı oluşturulmaz
- AI özellikleri tıbbi teşhis değildir — her AI çıktısında disclaimer gösterilir
- Uygulama kendi başına tıbbi tavsiye vermez, sadece resmi veri kaynaklarından bilgi sunar
