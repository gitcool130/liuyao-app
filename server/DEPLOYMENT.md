# 六爻助手服务端部署与更新备忘

> 目的：避免每次更新 APK 时重复踩坑（传错目录、build 号/MD5 不一致等）。

## 服务器信息

- **主机**：`root@100.64.7.62`（Tailscale 内网，公网 SSH 被 firewalld 屏蔽）
- **服务目录**：`/opt/liuyao-server/`
- **PM2 进程名**：`liuyao-server`
- **HTTP 端口**：`3456`
- **APK 下载目录**：`/opt/liuyao-server/public/apk/`
- **APK 文件名**：`liuyao-assistant.apk`
- **本地服务端源码**：`liuyao-app/server/server.js`

## 更新 APK 的标准步骤

1. 在本地编译并确认 build 号
   ```bash
   cd /Users/bobo/projects/liuyao-app
   ./build_apk.sh
   ```
   记住输出的 `buildNumber`（如 `73`）。

2. 上传到服务器的正确目录
   ```bash
   scp build/app/outputs/flutter-apk/app-release.apk root@100.64.7.62:/opt/liuyao-server/public/apk/liuyao-assistant.apk
   ```
   ⚠️ 不要传到 `/opt/liuyao-app/`，PM2 实际运行目录是 `/opt/liuyao-server/`。

3. 登录服务器校验文件
   ```bash
   ssh root@100.64.7.62
   md5sum /opt/liuyao-server/public/apk/liuyao-assistant.apk
   ls -lh /opt/liuyao-server/public/apk/liuyao-assistant.apk
   ```

4. 确认 `server.js` 中的版本与 build 号
   - 修改 `/opt/liuyao-server/server.js` 的 `CURRENT_VERSION.buildNumber`。
   - `version` 应与 `pubspec.yaml` 中的 `version` 一致。
   - **MD5 已改为运行时动态计算**，不再硬编码，无需手动修改。

5. 重启服务
   ```bash
   pm2 restart liuyao-server
   pm2 show liuyao-server
   ```

6. 验证更新接口
   ```bash
   curl -s http://127.0.0.1:3456/api/check_update | python3 -m json.tool
   ```
   确认返回的 `buildNumber`、`apkSize`、`md5` 与实际 APK 一致。

## 关键路径与命令速查

| 操作 | 命令/路径 |
|------|----------|
| 查看 PM2 状态 | `pm2 show liuyao-server` |
| 查看服务日志 | `pm2 logs liuyao-server` |
| 重启服务 | `pm2 restart liuyao-server` |
| 本地源码 | `/Users/bobo/projects/liuyao-app/server/server.js` |
| 远程源码 | `/opt/liuyao-server/server.js` |
| 远程 APK | `/opt/liuyao-server/public/apk/liuyao-assistant.apk` |
| 检查更新接口 | `GET http://100.64.7.62:3456/api/check_update` |

## 常见错误

1. **上传到了 `/opt/liuyao-app/`**：PM2 的 `exec cwd` 是 `/opt/liuyao-server/`，静态文件服务读取的是该目录下的 `public/apk/`。
2. **`buildNumber` 没改**：App 对比本地 build 号与接口返回的 `buildNumber`，若小于等于本地则不会提示更新。
3. **MD5 不一致**：以前 `server.js` 里硬编码 `md5`，容易忘记更新；现已改为读取 APK 文件实时计算。
4. **APK 文件名不对**：接口固定返回 `/apk/liuyao-assistant.apk`，上传后必须重命名为该文件名。
