# ─────────────────────────────────────────────────────
# Module   : USER_GUIDE.md (User Manual & Operating Guide)
# ─────────────────────────────────────────────────────

# Smart Notification Timeline & Tracker — User Guide (A to Z)

Welcome to **Smart Notification Timeline & Tracker**! This guide walks you through every step of using the app, from installing the APK and granting Android system permissions, to managing app filters, tracking incoming alerts, and exporting your notification history to JSON.

---

## 📑 Table of Contents
1. [What is this App?](#1-what-is-this-app)
2. [Step 1: Installing the Release APK](#2-step-1-installing-the-release-apk)
3. [Step 2: First Launch & Security Gate](#3-step-2-first-launch--security-gate)
4. [Step 3: Granting Android Notification Access](#4-step-3-granting-android-notification-access)
5. [Step 4: How Notification Tracking Works](#5-step-4-how-notification-tracking-works)
6. [Step 5: Managing Installed App Filters](#6-step-5-managing-installed-app-filters)
7. [Step 6: Navigating the Timeline Feed & Tracker Icons](#7-step-6-navigating-the-timeline-feed--tracker-icons)
8. [Step 7: Switching Dark / Light Themes](#8-step-7-switching-dark--light-themes)
9. [Step 8: Exporting Notification History to JSON](#9-step-8-exporting-notification-history-to-json)
10. [Step 9: Security Settings & Changing Passcode](#10-step-9-security-settings--changing-passcode)
11. [Android 10 through Android 16 Compatibility Notes](#11-android-10-through-android-16-compatibility-notes)
12. [Troubleshooting & Frequently Asked Questions (FAQ)](#12-troubleshooting--frequently-asked-questions-faq)

---

## 1. What is this App?
**Smart Notification Timeline & Tracker** is a privacy-first, 100% offline Android application that automatically captures incoming notifications from your apps (WhatsApp, Instagram, Gmail, Slack, Telegram, SMS, etc.) and organizes them into an uncluttered, searchable chronological timeline.

- **100% Offline & Private**: All notification records are stored locally on your device in a non-blocking SQLite database (`notification_tracker.db`). Zero servers, zero telemetry, zero cloud data transfer.
- **Selective Logging**: By default, it captures notifications from all apps, but you can turn off logging for specific apps (e.g. banking apps or confidential messages) anytime.
- **Multi-Tier Resilience**: Settings and tracking states are backed by 3-tier persistence (Fast Memory Cache + SQLite Database + Keystore Hardware Security) so settings never reset.

---

## 2. Step 1: Installing the Release APK
1. Download the release APK from the GitHub Actions build artifact or releases.
2. Transfer or open the `.apk` file on your Android device.
3. Tap the `.apk` file to start installation:
   - If Android prompts **"Install unknown apps"**, tap **Settings** and turn on **"Allow from this source"**.
   - Tap **Install**, then tap **Open**.

---

## 3. Step 2: First Launch & Security Gate
When you open the app, you are greeted by the **Security Check** lock screen:
- **Biometric Prompt**: If your device has fingerprint or face unlock enrolled, the biometric prompt appears automatically. Scan your fingerprint to unlock.
- **Fallback 6-Digit PIN**: If biometrics are not used, enter your 6-digit passcode.
  - **Default PIN**: `123456`
- Once unlocked, you enter the main **Timeline Screen**.

---

## 4. Step 3: Granting Android Notification Access
To allow the app to receive notifications from the Android operating system, Android requires an explicit system permission called **Notification Access**:

1. At the top of the Timeline, you will see a yellow banner:  
   *"Notification Access required to track incoming alerts."*
2. Tap the **"Enable"** button on the banner (or go to **Settings > Android Notification Access**).
3. Android will open the **Device & app notifications** (or **Special app access > Notification access**) system screen.
4. Find **"Smart Notification Timeline"** in the list and toggle the switch **ON**.
5. When Android prompts *"Allow notification access?"*, tap **Allow**.
6. Switch back to the app. The app automatically detects the permission on resume, the yellow banner disappears, and the status indicator displays **"Tracker Active"** with a green status dot. The background service starts automatically.

---

## 5. Step 4: How Notification Tracking Works
Once Android Notification Access is granted:
- **Automatic Background Listener**: Android OS routes notification events directly to the app's background listener service.
- **Live Stream Synchronization**: If you have the app open, incoming notifications appear on your timeline instantly without needing to refresh or pull down.
- **Centralized Settings Control**:
  - Tap the **Settings icon** (gear) in the top-right of the Timeline.
  - Toggle **"Capture Notifications"** OFF to temporarily pause tracking.
  - Toggle it back ON to resume tracking (the service will automatically restart).
  - All setting changes are saved instantly and persist across device restarts.

---

## 6. Step 5: Managing Installed App Filters
By default, the app captures notifications from **all installed apps**. You can customize which apps are logged:

1. Tap the **Settings icon** (gear) in the top-right of the Timeline, then tap **"Installed App Filters"**.
2. The screen displays all installed applications on your phone (e.g. WhatsApp, Instagram, Telegram, YouTube, Chrome, etc.) with custom **App Tracker Icon Badges**.
3. **Filter Categories**:
   - **All Apps**: Complete list of applications on your phone.
   - **User Apps**: Apps you downloaded from the Google Play Store or sideloaded.
   - **System Apps**: Pre-installed Android apps.
4. **Search**: Type any app name or package identifier in the search bar.
5. **Toggle Rules**: Toggle the switch next to any app **OFF** to stop capturing its notifications, or **ON** to track it.
6. **Bulk Controls**:
   - Tap **"All On"** in the top bar to enable tracking for all apps.
   - Tap **"All Off"** to disable all apps.

---

## 7. Step 6: Navigating the Timeline Feed & Tracker Icons
The main screen displays your notifications arranged chronologically:
- **Sticky Date Sections**: Grouped into clean headers ("Today", "Yesterday", or "04 September 2026") with total item counters.
- **Timeline Cards**: Each card displays:
  - **App Tracker Icon Badge**: Distinctive visual badge with branded color accents for major apps (WhatsApp, Gmail, YouTube, Telegram, Instagram, Chrome, Messages, Spotify, etc.) or a minimalist tracker radar badge with the app's initial.
  - App name in bold.
  - Time received (e.g., "10:45 AM").
  - Title (1 line constrained).
  - Message body (2 lines max).
  - Vertical rail line connecting events throughout the day.
- **View Full Details**: Tap any card to open a bottom sheet showing the complete unabbreviated message, package name, and exact timestamp.
- **Search Feed**: Type in the search bar to filter your timeline by app name, title, or message text in real time.
- **Delete / Undo**: Swipe any card to the left to delete it. An **"Undo"** action appears for 3 seconds if you change your mind.

---

## 8. Step 7: Switching Dark / Light Themes
You can change the visual theme anytime:
1. Tap the **Settings icon** (gear) in the top-right of the Timeline.
2. In the **Appearance & Theme** section, choose:
   - **Dark**: High-contrast OLED dark mode (ideal for night scanning and battery conservation).
   - **Light**: Crisp, clean daylight theme.
   - **System**: Automatically matches your Android system setting.
3. Your preference is persisted immediately.

---

## 9. Step 8: Exporting Notification History to JSON
You can export your notification history into a structured JSON file and share it:
1. Open **Settings** (gear icon) > tap **"Export Timeline to JSON"**.
2. In the **Export Dialog**:
   - **Quick Presets**: Tap **"Today"**, **"Last 7 Days"**, or **"Last 30 Days"**.
   - **Custom Range**: Tap **"Custom"** to select any start and end dates via the calendar picker.
3. View the live record counter (e.g. *"142 records found"*).
4. Tap **"Share JSON"**:
   - The app generates a formatted `.json` file containing all selected notifications with metadata.
   - The native Android Share Sheet opens automatically.
   - Choose where to send or save it (Google Drive, WhatsApp, Telegram, Email, or "Save to Files").

---

## 10. Step 9: Security Settings & Changing Passcode
Your notification timeline is protected by hardware encryption and a passcode:
1. Open **Settings** > **Security & Authentication**.
2. **Biometric Unlock**: Toggle ON or OFF to enable/disable fingerprint/face prompts on launch.
3. **Change 6-Digit Passcode**: Tap to change your PIN:
   - Step 1: Enter your current PIN (default: `123456`).
   - Step 2: Enter your new 6-digit PIN.
   - Step 3: Re-enter the new PIN to confirm.
4. Passcodes are securely stored in hardware-backed storage.

---

## 11. Android 10 through Android 16 Compatibility Notes

This application has been tested and engineered for Android 10 through Android 16:

- **Android 14, 15 & 16 (API 34, 35, 36)**:
  - Supports Android 14+ Foreground Service rules (`FOREGROUND_SERVICE_SPECIAL_USE` permission, `android:foregroundServiceType="specialUse"`, and `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` declared). This prevents the Android 14+ fatal service launch crash.
- **Android 11, 12 & 13 (API 30, 31, 32, 33)**:
  - Declares `QUERY_ALL_PACKAGES` permission and performs package manager queries on a background worker thread, ensuring the app filter screen never blocks the UI or gets stuck on loading.
- **Android 10 (API 29)**:
  - Implements 3-tier settings persistence (In-Memory + SQLite + Keystore) to bypass Tink/EncryptedSharedPreferences resets on legacy Android 10 devices.

---

## 12. Troubleshooting & Frequently Asked Questions (FAQ)

### Q: Why did the app stop capturing notifications?
1. **Verify Notification Access**: Open **Settings** in the app. If the status says *"Permission Required"*, tap **"Enable"** to grant access.
2. **Check the Master Switch**: Ensure **"Capture Notifications"** in Settings is toggled ON.
3. **Check App Filters**: Go to **Settings > Installed App Filters** and verify that the target app is toggled ON.
4. **Exempt from Android Battery Optimization**: Some phone manufacturers (Xiaomi/MIUI, Samsung/OneUI, Oppo/ColorOS, Vivo) aggressively kill background processes. To ensure 24/7 logging:
   - Go to phone `Settings > Apps > Smart Notification Timeline > Battery`.
   - Set battery usage to **"Unrestricted"** (or turn off battery optimization).

### Q: What is the default PIN?
The default PIN is **`123456`**. You can change it in **Settings > Change 6-Digit Passcode**.

### Q: Can I delete all notifications and start fresh?
Yes. Go to **Settings > Data Management & Export > Clear All Timeline History**. Confirm the prompt to wipe all records.

---

*Enjoy complete control and visibility over your Android notifications with Smart Notification Timeline & Tracker!*

