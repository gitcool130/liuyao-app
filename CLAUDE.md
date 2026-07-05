# 六爻助手 (LiuYao App)

## Project Overview

六爻排盘 Flutter App，支持摇卦、手动输入、OCR识别排盘。采用传统纳甲筮法，自动计算六爻、六亲、六神、伏神、神煞。

## Architecture

- `lib/` — Flutter app source
  - `screens/` — UI pages (HomeScreen, ResultScreen, UnlockScreen, etc.)
  - `widgets/` — Reusable widgets (YaoTable, ShenshaCard, CoinWidget, etc.)
  - `algorithms/` — Core divination logic (constants, ganzhi, gua, shensha, etc.)
  - `services/` — Feature locks, update manager, OCR, parsers
  - `models/` — Data models (DivinationRecord, YaoLine, GuaInfo, etc.)
  - `providers/` — State management (DivinationProvider, HistoryProvider, SettingsProvider)
  - `database/` — SQLite via sqflite
  - `utils/` — AutoSave, ExportHelper
- `server/` — Node.js backend (update distribution, online verification, unlock requests)
- `admin_tool/` — Separate Flutter app for admin (code generation, pending requests, config)

## Build Commands

```bash
# Main app (with obfuscation + auto version bump)
cd liuyao-app && ./build_apk.sh

# Admin tool
cd liuyao-app/admin_tool && flutter build apk --release
```

## Key Conventions

- **State management**: Provider pattern
- **Versioning**: `lib/version.dart` + `pubspec.yaml` + `android/app/build.gradle.kts` synced by `build_apk.sh`
- **Build number** auto-increments; patch version bumps every 20 builds
- **Unlock system**: Server-based (no local HMAC key). Requests stored in SQLite with AES-encrypted remarks
- **HTML website** at `/var/www/html/` on server (zhouyi.html + books.html)

## Server

- Node.js + Express + better-sqlite3 on port 3456
- Tailscale VPN for SSH (public SSH blocked by firewalld)
- PM2 managed, systemd autostart
- APK update MD5 is computed at runtime from the actual file; no hardcoded MD5
- **Deployment/update checklist**: see `server/DEPLOYMENT.md`
  - Upload APK to `/opt/liuyao-server/public/apk/liuyao-assistant.apk` only
  - Update `CURRENT_VERSION.buildNumber` to match the new APK
  - Restart with `pm2 restart liuyao-server`
  - Verify via `curl http://100.64.7.62:3456/api/check_update`

## Git

- Main app + server code in root, admin_tool in `admin_tool/`
- Server running code at `/opt/liuyao-server/server.js`; local copy at `server/server.js`
