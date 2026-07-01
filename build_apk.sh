#!/bin/bash
flutter build apk --release "$@" && \
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/liuyao-assistant.apk && \
echo "✅ build/app/outputs/flutter-apk/liuyao-assistant.apk"
