# ─────────────────────────────────────────────────────
# Module   : USER_GUIDE.md (User Manual & Operating Guide)
# ─────────────────────────────────────────────────────

# Smart Notification Timeline & Tracker — User Guide (A to Z)

Welcome to **Smart Notification Timeline & Tracker**! This guide walks you through every step of using the app, from installing the APK and granting Android system permissions, to managing app filters and exporting your notification history to JSON.

---

## 📑 Table of Contents
1. [What is this App?](#1-what-is-this-app)
2. [Step 1: Installing the Release APK](#2-step-1-installing-the-release-apk)
3. [Step 2: First Launch & Security Gate](#3-step-2-first-launch--security-gate)
4. [Step 3: Granting Android Notification Access](#4-step-3-granting-android-notification-access)
5. [Step 4: How Notification Tracking Works](#5-step-4-how-notification-tracking-works)
6. [Step 5: Managing Installed App Filters](#6-step-5-managing-installed-app-filters)
7. [Step 6: Navigating the Timeline Feed](#7-step-6-navigating-the-timeline-feed)
8. [Step 7: Switching Dark / Light Themes](#8-step-7-switching-dark--light-themes)
9. [Step 8: Exporting Notification History to JSON](#9-step-8-exporting-notification-history-to-json)
10. [Step 9: Security Settings & Changing Passcode](#10-step-9-security-settings--changing-passcode)
11. [Troubleshooting & Frequently Asked Questions (FAQ)](#11-troubleshooting--frequently-asked-questions-faq)

---

## 1. What is this App?
**Smart Notification Timeline & Tracker** is a privacy-first Android application that automatically captures incoming notifications from your apps (WhatsApp, Instagram, Gmail, Slack, Telegram, SMS, etc.) and organizes them into a clean, searchable timeline grouped by date.

- **100% Offline & Private**: All notification records are stored exclusively on your device in a local encrypted SQLite database (`notification_tracker.db`). No servers, no tracking, zero cloud data transfer.
- **Selective Logging**: By default, it captures notifications from all apps, but you can turn off logging for specific apps (e.g. banking apps or confidential messages) at any time.

---

## 2. Step 1: Installing the Release APK
1. Download the `smart-notification-tracker-release-apk` artifact from the GitHub Actions build.
2. Transfer or download the `.apk` file onto your Android device.
3. Tap the `.apk` file to start installation:
   - If Android shows **"Install unknown apps"**, tap **Settings** and turn on **"Allow from this source"**.
   - Tap **Install**, then tap **Open**.

---

## 3. Step 2: First Launch & Security Gate
When you open the app, you are greeted by the **Security Check** lock screen:
- **Biometric Prompt**: If your device has a fingerprint reader or face unlock enrolled, the biometric prompt appears automatically. Scan your fingerprint to unlock.
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
6. Switch back to the app. The yellow banner will disappear, and the status indicator in the top-left will show **"Tracker Active"** with a green dot.

---

## 5. Step 4: How Notification Tracking Works
Once Android Notification Access is granted:
- **Automatic & Battery-Friendly**: Android OS routes notifications directly to the app in the background when they arrive. There is no heavy background loop draining your battery.
- **Live Stream**: If you have the app open, incoming notifications appear on your timeline instantly without needing to refresh.
- **Master Pause/Resume Switch**:
  - Open **Settings** (gear icon in top right).
  - Toggle **"Capture Notifications"** OFF to temporarily pause tracking.
  - Toggle it back ON to resume.

---

## 6. Step 5: Managing Installed App Filters
By default, the app captures notifications from **all installed apps**. You can selectively disable apps you do not want to record:

1. Tap the **Filter icon** (sliders) on the top bar, or go to **Settings > Installed App Filters**.
2. The screen displays **every installed application on your phone** (e.g. WhatsApp, Instagram, Telegram, YouTube, Chrome, etc.).
3. **Filter Categories**:
   - **All Apps**: Full list of applications.
   - **User Apps**: Apps you downloaded from the Google Play Store.
   - **System Apps**: Pre-installed Android apps.
4. **Search**: Type any app name or package identifier in the search bar.
5. **Toggle**: Simply toggle the switch next to any app **OFF** to stop capturing its notifications, or **ON** to track it.
6. **Quick Actions**:
   - Tap **"All On"** to enable tracking for all apps.
   - Tap **"All Off"** to disable all apps.

---

## 7. Step 6: Navigating the Timeline Feed
The main screen displays your notifications arranged chronologically:
- **Date Sections**: Grouped into sticky headers ("Today", "Yesterday", or "04 September 2026") with an item count badge.
- **Timeline Cards**: Each notification card displays:
  - App name in bold (with an indigo dot).
  - Time received (e.g., "10:45 AM").
  - Title (1 line).
  - Message body (2 lines max).
  - Vertical rail line connecting events throughout the day.
- **View Full Details**: Tap any card to open a bottom sheet showing the complete unabbreviated message, package name, and full timestamp.
- **Search Feed**: Type in the top search bar to filter your timeline by app name, title, or message text in real time.
- **Delete / Undo**: Swipe any notification card to the left to delete it. An **"Undo"** button appears at the bottom for 3 seconds if you change your mind.

---

## 8. Step 7: Switching Dark / Light Themes
You can change the visual theme anytime:
1. Tap the **Settings icon** (gear) in the top-right of the Timeline.
2. In the **Appearance & Theme** card, select:
   - **Dark**: High-contrast OLED dark mode (recommended for battery savings).
   - **Light**: Crisp, clean white aesthetic.
   - **System**: Automatically matches your Android system setting.
3. The app updates its colors immediately and remembers your preference.

---

## 9. Step 8: Exporting Notification History to JSON
You can export your notification history into a structured JSON file and share it via any Android app:
1. Tap the **Share icon** on the Timeline header (or go to **Settings > Export Timeline to JSON**).
2. The **Export Dialog** opens:
   - **Quick Presets**: Tap **"Today"**, **"Last 7 Days"**, or **"Last 30 Days"**.
   - **Custom Range**: Tap **"Custom"** to open a calendar date picker and select any start and end dates.
3. Inspect the record counter (e.g. *"142 records found"*).
4. Tap **"Share JSON"**:
   - The app generates a formatted `.json` file containing all selected notifications with metadata.
   - The native Android Share Sheet opens automatically.
   - Choose where to send or save it (Google Drive, WhatsApp, Telegram, Email, or "Save to Files").

---

## 10. Step 9: Security Settings & Changing Passcode
Your notification timeline is protected by hardware encryption and a passcode:
1. Open **Settings**.
2. Under **Security & Authentication**:
   - **Biometric Unlock**: Toggle ON or OFF to enable/disable fingerprint prompts on launch.
   - **Change 6-Digit Passcode**: Tap this tile to change your PIN:
     - Step 1: Enter your current PIN (default: `123456`).
     - Step 2: Enter your new 6-digit PIN.
     - Step 3: Re-enter the new PIN to confirm.
3. The new passcode is securely saved in Android hardware-backed encrypted storage (`EncryptedSharedPreferences`).

---

## 11. Troubleshooting & Frequently Asked Questions (FAQ)

### Q: Why did the app stop capturing notifications?
1. Check **Notification Access**: Go to **Settings** in the app. If the status says *"Permission Required"*, tap **"Enable"** to grant access in Android Settings.
2. Check the **Master Switch**: Ensure **"Capture Notifications"** in Settings is toggled ON.
3. Check **App Filters**: Verify that the app sending the notifications is not toggled OFF in **Installed App Filters**.
4. Check **Android Battery Optimization**: Some Android phone manufacturers (Xiaomi/MIUI, Samsung/OneUI, Oppo/ColorOS) aggressively kill background processes. To ensure uninterrupted logging:
   - Go to your phone's `Settings > Apps > Smart Notification Timeline > Battery`.
   - Set battery usage to **"Unrestricted"** (or turn off battery optimization).

### Q: What is the default PIN?
The default PIN on first install is **`123456`**. You can change it at any time in **Settings > Change 6-Digit Passcode**.

### Q: Can I delete all notifications and start fresh?
Yes. Go to **Settings > Data Management & Export > Clear All Timeline History**. Confirm the prompt to wipe the database.

---

*Enjoy complete control and visibility over your Android notifications with Smart Notification Timeline & Tracker!*
