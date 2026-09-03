#!/bin/bash

# Define the root project name
ROOT_DIR="/Users/hassan/Documents/MyStuff/projects/mobile-apps/notification_timeline_app"

echo "Creating directory structure for $ROOT_DIR..."

# Create all folders using mkdir -p (creates parent directories automatically)
mkdir -p "$ROOT_DIR/.github/workflows"
mkdir -p "$ROOT_DIR/android/app/src/main"
mkdir -p "$ROOT_DIR/lib/core/database"
mkdir -p "$ROOT_DIR/lib/core/security"
mkdir -p "$ROOT_DIR/lib/core/theme"
mkdir -p "$ROOT_DIR/lib/core/utils"
mkdir -p "$ROOT_DIR/lib/features/auth/presentation"
mkdir -p "$ROOT_DIR/lib/features/notifications/data"
mkdir -p "$ROOT_DIR/lib/features/notifications/models"
mkdir -p "$ROOT_DIR/lib/features/notifications/presentation/widgets"
mkdir -p "$ROOT_DIR/lib/features/settings/presentation"

echo "Creating placeholder files..."

# Root and configuration files
touch "$ROOT_DIR/.github/workflows/build_apk.yml"
touch "$ROOT_DIR/pubspec.yaml"
touch "$ROOT_DIR/android/app/src/main/AndroidManifest.xml"

# Lib / Core files
touch "$ROOT_DIR/lib/main.dart"
touch "$ROOT_DIR/lib/core/database/database_helper.dart"
touch "$ROOT_DIR/lib/core/security/biometric_service.dart"
touch "$ROOT_DIR/lib/core/security/secure_storage.dart"
touch "$ROOT_DIR/lib/core/theme/app_theme.dart"
touch "$ROOT_DIR/lib/core/utils/json_exporter.dart"

# Lib / Feature files
touch "$ROOT_DIR/lib/features/auth/presentation/lock_screen.dart"
touch "$ROOT_DIR/lib/features/auth/presentation/passcode_modal.dart"
touch "$ROOT_DIR/lib/features/notifications/data/notification_listener_service.dart"
touch "$ROOT_DIR/lib/features/notifications/models/notification_model.dart"
touch "$ROOT_DIR/lib/features/notifications/presentation/timeline_screen.dart"
touch "$ROOT_DIR/lib/features/notifications/presentation/widgets/timeline_card.dart"
touch "$ROOT_DIR/lib/features/notifications/presentation/widgets/date_header.dart"
touch "$ROOT_DIR/lib/features/settings/presentation/app_filter_screen.dart"
touch "$ROOT_DIR/lib/features/settings/presentation/export_dialog.dart"

echo "Project structure created successfully inside '$ROOT_DIR/'!"