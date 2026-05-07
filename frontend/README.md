# MediTrack — Flutter Frontend

Koç Üniversitesi COMP491 bitirme projesi. Reçete ve ilaç takip uygulaması.

## Kurulum

### Gereksinimler

- Flutter SDK >= 3.x
- Dart >= 3.x
- Xcode (iOS için)
- Android Studio (Android için)
- Firebase projesi kurulu olmalı

### Adımlar

**1. Repoyu klonla ve frontend klasörüne gir:**
```bash
git clone https://github.com/COMP491-MediTrack/MediTrack-Project.git
cd MediTrack-Project/frontend
```

> Repoyu zaten klonladıysan `git pull` ile güncelle.

**2. Bağımlılıkları yükle:**
```bash
flutter pub get
```

**4. Code generation çalıştır (her pull sonrası şart):**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**5. Uygulamayı başlat:**
```bash
flutter run
```

> **Backend:** Render'da canlıda, ayrıca bir şey yapman gerekmiyor. Uygulama otomatik olarak `https://meditrack-project-6io1.onrender.com` adresine bağlanır.

---

## Mimari

**Clean Architecture + Feature-Layered**

```
lib/
├── core/
│   ├── constants/     # AppConstants, API URL, Firestore koleksiyon isimleri
│   ├── di/            # GetIt + injectable dependency injection
│   ├── errors/        # Failure sınıfları
│   ├── network/       # Dio client + interceptor
│   ├── router/        # GoRouter + route isimleri
│   └── theme/         # AppTheme, AppColors, AppTypography, AppSpacing
└── features/
    ├── auth/          # Firebase Auth, login/register, rol yönetimi ✅
    ├── dashboard/     # Doctor, Patient ve Lab dashboard ✅
    ├── prescription/  # Reçete oluşturma, listeleme, DDI kontrolü ✅
    ├── lab_results/   # Tahlil istekleri, lab sonuçları PDF ✅
    └── ai/            # Semptom analizi, reçete özeti (yapılacak)
```

Her feature kendi içinde:
```
feature/
├── data/          # Model, DataSource, Repository implementasyonu
├── domain/        # Entity, Repository interface, UseCase
└── presentation/  # Cubit/State, Page, Widget
```

---

## Kullanılan Teknolojiler

| Paket | Amaç |
|-------|------|
| `flutter_bloc` | State management (Cubit / Bloc) |
| `go_router` | Navigation ve rol bazlı routing |
| `get_it` + `injectable` | Dependency injection |
| `dio` | HTTP client (FastAPI çağrıları) |
| `firebase_auth` | Kullanıcı girişi/kaydı |
| `cloud_firestore` | Uygulama verisi |
| `firebase_storage` | PDF yükleme |
| `hive` | Local cache |
| `shared_preferences` | Basit key-value storage |
| `dartz` | Either<Failure, Success> error handling |
| `equatable` | Value equality |
| `flutter_screenutil` | Responsive layout (referans: 390x844) |

---

## Roller

| Rol | Açıklama |
|-----|----------|
| `doctor` | Reçete yazar, hasta listesini görür, DDI kontrolü yapar |
| `patient` | Kayıt olurken doktor seçer, reçetelerini görür, semptom girer |
| `lab` | Tüm tahlil isteklerini görür, bekleyenler için PDF sonucu yükler |

---

## Önemli Kurallar

- Tüm boyutlar `flutter_screenutil` ile `.w`, `.h`, `.sp`, `.r` olarak verilir
- Error handling `Either<Failure, Success>` pattern ile yapılır
- DI için elle kayıt yapılmaz, `injectable` annotation'ları kullanılır
- Her değişiklik sonrası `build_runner` çalıştırılır
- State sınıfları `Equatable` extend eder
