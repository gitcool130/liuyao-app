#!/bin/bash
# 编译管理工具APK并命名为 liuyao-admin-tool.apk
cd "$(dirname "$0")"

echo "📦 编译管理工具..."
flutter build apk --release

if [ $? -eq 0 ]; then
    cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/liuyao-admin-tool.apk
    echo "✅ build/app/outputs/flutter-apk/liuyao-admin-tool.apk"
fi
