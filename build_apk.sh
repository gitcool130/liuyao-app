#!/bin/bash
set -e

# 自动递增构建号 + 同步版本到所有配置文件
VERSION_FILE="lib/version.dart"
PUBSPEC="pubspec.yaml"
ANDROID_BUILD="android/app/build.gradle.kts"

# 读取当前版本号
CURRENT_VERSION=$(grep 'const String appVersion' "$VERSION_FILE" | sed "s/.*'\(.*\)'.*/\1/")
CURRENT_BUILD=$(grep 'const int appBuildNumber' "$VERSION_FILE" | sed 's/.*appBuildNumber = \([0-9]*\).*/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "📦 v$CURRENT_VERSION 构建#$CURRENT_BUILD → v$CURRENT_VERSION 构建#$NEW_BUILD"

# 更新 version.dart
sed -i '' "s/appBuildNumber = $CURRENT_BUILD/appBuildNumber = $NEW_BUILD/" "$VERSION_FILE"

# 更新 pubspec.yaml
sed -i '' "s/version: $CURRENT_VERSION+$CURRENT_BUILD/version: $CURRENT_VERSION+$NEW_BUILD/" "$PUBSPEC"

# 更新 android build.gradle.kts
sed -i '' "s/versionCode = $CURRENT_BUILD/versionCode = $NEW_BUILD/" "$ANDROID_BUILD"

# 编译
flutter build apk --release --obfuscate --split-debug-info=build/debug-info "$@" && \
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/liuyao-assistant.apk && \
echo "✅ build/app/outputs/flutter-apk/liuyao-assistant.apk"
