#!/bin/bash
set -e

# 自动递增构建号 + 每20次构建升级小版本号
VERSION_FILE="lib/version.dart"
PUBSPEC="pubspec.yaml"
ANDROID_BUILD="android/app/build.gradle.kts"

# 读取当前版本号
CURRENT_VERSION=$(grep 'const String appVersion' "$VERSION_FILE" | sed "s/.*'\(.*\)'.*/\1/")
CURRENT_BUILD=$(grep 'const int appBuildNumber' "$VERSION_FILE" | sed 's/.*appBuildNumber = \([0-9]*\).*/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

# 解析版本号各部分
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# 构建号每20次升级一次patch版本
if [ $((NEW_BUILD % 20)) -eq 0 ]; then
    PATCH=$((PATCH + 1))
fi

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "📦 v$CURRENT_VERSION 构建#$CURRENT_BUILD → v$NEW_VERSION 构建#$NEW_BUILD"

# 更新 version.dart
sed -i '' "s/appVersion = '$CURRENT_VERSION'/appVersion = '$NEW_VERSION'/" "$VERSION_FILE"
sed -i '' "s/appBuildNumber = $CURRENT_BUILD/appBuildNumber = $NEW_BUILD/" "$VERSION_FILE"

# 更新 pubspec.yaml
sed -i '' "s/version: $CURRENT_VERSION+$CURRENT_BUILD/version: $NEW_VERSION+$NEW_BUILD/" "$PUBSPEC"

# 更新 android build.gradle.kts
sed -i '' "s/versionCode = $CURRENT_BUILD/versionCode = $NEW_BUILD/" "$ANDROID_BUILD"
sed -i '' "s/versionName = \"$CURRENT_VERSION\"/versionName = \"$NEW_VERSION\"/" "$ANDROID_BUILD"

# 编译
flutter build apk --release --obfuscate --split-debug-info=build/debug-info "$@" && \
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/liuyao-assistant.apk && \
echo "✅ build/app/outputs/flutter-apk/liuyao-assistant.apk"
