#!/bin/bash
# Dart代码混淆(--obfuscate)增加逆向难度，不影响Android原生库
# 调试符号保留在 build/debug-info，不影响运行时
flutter build apk --release --obfuscate --split-debug-info=build/debug-info "$@" && \
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/liuyao-assistant.apk && \
echo "✅ build/app/outputs/flutter-apk/liuyao-assistant.apk"
