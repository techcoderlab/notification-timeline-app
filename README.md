# ─────────────────────────────────────────────────────
# Module   : README.md (Architecture & Documentation)
# ─────────────────────────────────────────────────────

# Smart Notification Timeline & Tracker

A production-grade, highly performant Android Flutter application built with Clean Architecture, SQLite non-blocking indexing, Biometric/Passcode zero-trust security, and a minimalist date-grouped timeline UI.

---

## 🏛️ Architecture Overview

The project follows a **Feature-First Clean Architecture** with strict layer separation:

```
lib/
├── main.dart                                        # Application bootstrap & lifecycle
├── core/
│   ├── database/
│   │   └── database_helper.dart                     # SQLite with WAL mode & composite indexes
│   ├── security/
│   │   ├── biometric_service.dart                   # LocalAuth biometric orchestration
│   │   └── secure_storage.dart                      # Hardware-backed EncryptedSharedPreferences
│   ├── theme/
│   │   └── app_theme.dart                           # Minimalist OLED dark & clean light design system
│   └── utils/
│       └── json_exporter.dart                       # Date-range JSON serializer & native Share Sheet
└── features/
    ├── auth/
    │   └── presentation/
    │       ├── lock_screen.dart                     # Biometric-first gate with 6-digit PIN keypad
    │       └── passcode_modal.dart                  # Passcode update workflow & biometrics switch
    ├── notifications/
    │   ├── data/
    │   │   └── notification_listener_service.dart   # Background isolate listener & filter dispatch
    │   ├── models/
    │   │   └── notification_model.dart              # Notification & AppFilter domain entities
    │   └── presentation/
    │       ├── timeline_screen.dart                 # Live timeline feed with live stream sync
    │       └── widgets/
    │           ├── date_header.dart                 # Sticky section header with item counts
    │           └── timeline_card.dart               # Sleek timeline card with vertical connector rail
    └── settings/
        └── presentation/
            ├── app_filter_screen.dart               # Per-app toggle manager with bulk controls
            └── export_dialog.dart                   # Date range picker & record count preview
```

---

## 🚀 Key Features

1. **Background Notification Capturing**:
   - Implements `flutter_notification_listener` to intercept incoming Android notifications in a background isolate.
   - Pre-filters notifications against the SQLite `app_filters` table before disk writes.
2. **Indexed SQLite Persistence**:
   - `notifications` table with composite indexes on `timestamp DESC` and `package_name`.
   - SQLite WAL (Write-Ahead Logging) enabled for non-blocking concurrent reads and writes.
3. **Zero-Trust Security**:
   - Device Biometrics prompt triggered on app launch.
   - Tactile 6-digit fallback keypad backed by `FlutterSecureStorage` (default PIN: `123456`).
   - Shake feedback animation on incorrect PIN.
4. **Minimalist Timeline UX**:
   - Grouped chronologically by date ("Today", "Yesterday", "dd MMM yyyy").
   - Live debounced search across App Name, Title, and Message Body.
   - Swipe-to-delete with instantaneous local state reflection and undo capability.
5. **JSON Export & Native Share Sheet**:
   - Presets for Today, 7 Days, 30 Days, or Custom Date Range.
   - Generates pretty-printed JSON envelopes with metadata headers and triggers Android native Share Sheet.

---

## 📱 Android Permissions & Setup

The app requires Android Notification Access to listen to incoming events:
- Ensure `<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"/>` is present in `AndroidManifest.xml`.
- When launching the app, tap **"Enable"** on the notification banner or navigate to:
  `Settings > Apps > Special app access > Notification access > Smart Notification Timeline`.

---

## 🛠️ Build & CI/CD Pipeline

The `.github/workflows/build_apk.yml` file automates testing, code analysis, and release APK packaging:

```bash
# Run unit tests
flutter test

# Build release APK
flutter build apk --release
```
