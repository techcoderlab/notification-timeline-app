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
    │           ├── app_tracker_icon.dart            # Branded tracker icon badges for apps
    │           ├── date_header.dart                 # Sticky section header with item counts
    │           └── timeline_card.dart               # Sleek timeline card with vertical connector rail
    └── settings/
        └── presentation/
            ├── app_filter_screen.dart               # Per-app toggle manager with bulk controls
            ├── export_dialog.dart                   # Date range picker & record count preview
            └── settings_screen.dart                 # Centralized settings control center
```

---

## 🚀 Key Features

1. **Background Notification Capturing (Android 10 to 16)**:
   - Implements `flutter_notification_listener` with Android 14+ `FOREGROUND_SERVICE_SPECIAL_USE` declarations.
   - Intercepts incoming Android notifications in an isolated background thread and syncs live to the timeline feed.
2. **Indexed SQLite Persistence with Multi-Tier Cache**:
   - `notifications` table with composite indexes on `timestamp DESC` and `package_name`.
   - SQLite WAL (Write-Ahead Logging) enabled for non-blocking concurrent reads and writes.
   - Multi-tier settings architecture: In-Memory Cache + SQLite `app_settings` + Hardware Keystore.
3. **App Tracker Icon Badges**:
   - Dynamic, branded squircle badges for top communication and productivity apps (WhatsApp, Gmail, YouTube, Telegram, Instagram, Messages, Chrome, Spotify, etc.).
   - Modern radar badge fallback with capital letter identification for installed apps.
4. **Zero-Trust Security**:
   - Device Biometrics prompt triggered on app launch.
   - Tactile 6-digit fallback keypad backed by hardware secure storage (default PIN: `123456`).
5. **Minimalist Timeline UX**:
   - Grouped chronologically by date ("Today", "Yesterday", "dd MMM yyyy").
   - Live debounced search across App Name, Title, and Message Body.
   - Swipe-to-delete with instantaneous local state reflection and undo capability.
6. **JSON Export & Native Share Sheet**:
   - Presets for Today, 7 Days, 30 Days, or Custom Date Range.
   - Generates formatted JSON envelopes with metadata headers and triggers Android native Share Sheet.

---

## 📱 Android Permissions & Compatibility (Android 10 – 16)

- **Android Notification Access**:
  - `android.permission.BIND_NOTIFICATION_LISTENER_SERVICE`
- **Android 14+ Foreground Service**:
  - `android.permission.FOREGROUND_SERVICE_SPECIAL_USE`
  - Service type `specialUse` with `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`
- **Installed Apps Querying**:
  - `android.permission.QUERY_ALL_PACKAGES` executed on an asynchronous background thread
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

