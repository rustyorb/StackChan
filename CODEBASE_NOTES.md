# StackChan Codebase Notes

## Repo Shape

- `firmware/`: ESP-IDF firmware for M5Stack CoreS3-based StackChan.
- `app/`: iOS SwiftUI app, Xcode project only.
- `server/`: GoFrame backend on port `12800`, SQLite storage, REST APIs, and WebSocket relay.
- `remote/code/`: separate ESP-IDF/M5Unified ESP-NOW remote-control firmware.

## Firmware

- Entry point: `firmware/main/main.cpp`.
- Toolchain target: ESP-IDF `>=5.5.2`, README says `v5.5.4`.
- Board target: `CONFIG_BOARD_TYPE_M5STACK_STACK_CHAN`, ESP32-S3, 16 MB flash, PSRAM.
- Dependency fetcher: `firmware/fetch_repos.py`.
- Pinned external repos:
  - `components/mooncake` at `v2.3.3`
  - `components/mooncake_log` at `v1.5.0`
  - `components/smooth_ui_toolkit` at `v2.12.0`
  - `xiaozhi-esp32` at `v2.2.4`, patched by `patches/xiaozhi-esp32.patch`
  - `components/ArduinoJson` at `v7.4.2`
  - `components/esp-now` at commit `c33383de97f3ed2fc52117f5ef04f71990432e5d`

### Firmware Runtime Model

- `app_main()` initializes `Hal`, wires Smooth UI timing to HAL, installs Mooncake apps, and runs Mooncake until `Hal::requestXiaozhiStart()` is called.
- Opening the `AI.AGENT` app only sets the XiaoZhi start request. The main loop then uninstalls all Mooncake apps, destroys Mooncake, and starts XiaoZhi.
- `Hal::startXiaozhi()` starts a separate StackChan update task, enables motion auto sync/torque release, configures reminder UI behavior, then calls `hal_bridge::start_xiaozhi_app()`, which never returns.
- `StackChan` is a singleton containing optional avatar, optional motion, two neon-light channels, and an object pool of modifiers.

### Firmware Control Contracts

- Avatar JSON updates support `leftEye`, `rightEye`, `mouth` objects with `x`, `y`, `rotation`, `weight`, `size`.
- Motion JSON updates support `yawServo` and `pitchServo`.
  - Servo object can use `rotate`, or `angle` plus optional `speed`, or `angle` plus `spring.stiffness`/`spring.damping`.
- Dance JSON is an array of keyframes with avatar fields, servo fields, `leftRgbColor`, `rightRgbColor`, and `durationMs`.
- ESP-NOW remote packets are 8 bytes:
  - `[target-id uint8][yaw int16 LE][pitch int16 LE][speed int16 LE][laser-enabled uint8]`.

### Firmware Hotspots

- `firmware/main/hal/board/stackchan.cc`: board init, PMIC, I2C, touch, display, camera, battery, backlight, speaker.
- `firmware/main/hal/board/stackchan_display.cc`: XiaoZhi display adapter, avatar creation, chat/status-to-expression mapping, idle motion.
- `firmware/main/hal/hal_ws_avatar.cpp`: WebSocket avatar/call/video/dance bridge.
- `firmware/main/hal/hal_servo.cpp`: SCS servo mapping/calibration/torque behavior.
- `firmware/main/stackchan/json/json_helper.cpp`: app/server JSON command parser.
- `firmware/main/apps/app_avatar/app_avatar.cpp`: WebSocket-driven avatar app.
- `firmware/main/apps/app_dance/app_dance.cpp`: BLE-driven dance/control app.
- `firmware/main/apps/app_espnow_ctrl/app_espnow_ctrl.cpp`: ESP-NOW sender/receiver app.

## Server

- Entry point: `server/main.go`.
- Framework: GoFrame `v2.9.7`.
- WebSocket package: `server/internal/web_socket/web_socket.go`.
- Config: `server/manifest/config/config.yaml`, address `:12800`, SQLite link `sqlite::@file(/stackChan.sqlite)`.
- REST APIs are mounted under `/stackChan`; WebSocket is `/stackChan/ws`.

### Server WebSocket Protocol

- Binary packets are `[type byte][payload length uint32 big-endian][payload]`.
- Device types:
  - StackChan connects with query `mac=<mac>&deviceType=StackChan`.
  - App connects with query `mac=<mac>&deviceType=App&deviceId=<deviceId>`.
- The app often prepends a 12-character MAC string to payloads for directed commands.
- Message type constants align mostly with the iOS app and firmware:
  - `0x01` Opus
  - `0x02` JPEG
  - `0x03` avatar control
  - `0x04` motion control
  - `0x05` camera on
  - `0x06` camera off
  - `0x07` text message
  - `0x09` request call
  - `0x0A` refuse/decline call
  - `0x0B` agree/accept call
  - `0x0C` hangup/end call
  - `0x0D` update/set device name
  - `0x0E` get device name
  - `0x10` ping
  - `0x11` pong
  - `0x12` phone screen/video mode on
  - `0x13` phone screen/video mode off
  - `0x14` dance
  - `0x15` get avatar posture
  - `0x16` device offline
  - `0x17` device online

## iOS App

- Entry point: `app/StackChan/StackChanApp.swift`.
- Main shell: `app/StackChan/View/ContentView.swift`.
- Hard-coded backend URL: `app/StackChan/Network/Urls.swift`.
- WebSocket client: `app/StackChan/Network/WebSocketUtil.swift`.
- App-wide state/protocol helpers: `app/StackChan/AppState.swift`.
- Message type enum: `app/StackChan/Model/MessageModel.swift`.
- Avatar and motion controls: `app/StackChan/View/AvatarMotionControl.swift`.
- Dance editor: `app/StackChan/View/Dance.swift`.
- BLE provisioning/control helper: `app/StackChan/Utils/BlufiUtil.swift`.

## Fork Changes

- Backend WebSocket parser now validates packet length before slicing payload bytes.
- Backend WebSocket package passes normal `go test ./...` vet settings.
- Firmware StackChan WebSocket connection now includes `mac=<factoryMac>`.
- Firmware StackChan update task now runs at lower priority with a longer delay to reduce contention with XiaoZhi audio tasks.
- iOS `deviceOnline`/`deviceOffline` handling now maps to `true`/`false` respectively.
- Root helper scripts were added for starting/stopping the Go server:
  - `start.sh`
  - `start.bat`
  - `stop.sh`
  - `stop.bat`

## External References

- `espressif/esp-agents-firmware`: official Espressif voice-agent firmware reference. Useful as an information source for M5Stack CoreS3 audio/display/provisioning patterns, but not a current migration target.
- `xinnan-tech/xiaozhi-esp32-server`: canonical XiaoZhi backend direction. The Codex-hosted shell currently cannot clone it because DNS/thread creation fails, so `server-xz/` remains a local bridgehead until it can be fetched from a normal terminal.
- Android `StackChan World 1.1.4` APK/folder at `S:\Downloads\StackChan World 1.1.4` is the relevant phone app artifact for this user. It is a Flutter app whose `libapp.so` contains the app backend base `http://47.113.125.164:12800/`, WebSocket `ws://47.113.125.164:12800/stackChan/ws`, and XiaoZhi/account endpoints including `xiaozhi/token`, `xiaozhi/token/refresh`, `xiaozhi/generateLicenseToken`, `api/agents`, `api/agents/devices/activate`, `api/developers/devices`, `api/developers/generate-license`, `api/developers/agent-templates/list`, and `api/user/tts-list`.
- The Android app also contains BLE/Wi-Fi provisioning strings (`setWifi`, `sendWifiSetData`, `confirmWifi`, `cached_wifi_name`, `cached_wifi_password`, `wifiConnected`, `wifiConnectFailed`) and BLE UUIDs including `e2e5e5e0-1234-5678-1234-56789abcdef0` through `e2e5e5e4-1234-5678-1234-56789abcdef0`, `e2e5e5ff-1234-5678-1234-56789abcdef0`, and FFE1/FFE3/FFE4 characteristics.

## Local/Private Artifacts

- Full-device flash dumps, extracted partitions, and agent/runtime state are intentionally ignored and should stay out of public commits:
  - `stackchan-full-*.bin`
  - `chunks/`
  - `flash-backup-*/`
  - `.claude/`

## Remaining Breakpoints

- `app/StackChan/Network/Urls.swift` contains a hard-coded LAN IP.
- `firmware/main/hal/utils/secret_logic/secret_logic.cpp` weak default server URL is `http://localhost:3000`, which is not the Go server default and is unusable from device firmware unless overridden.
- `server/stackChan.sqlite` is committed with sample/user-looking data. Runtime DB state should usually be generated or mounted, not versioned as app source.
- Upload handling in `server/internal/service/file.go` accepts caller-controlled `Directory` and `Name` and writes under `file/` without path sanitization.

## Verification Done

- Ran `go test ./...`: passes.
- Smoke-tested `start.bat` and `stop.bat`: server starts on port `12800` and stops cleanly.
- ESP-IDF v5.5.4 is installed at `C:\esp\v5.5.4\esp-idf`, with tools under `C:\Espressif\tools`.
- In the Codex-hosted shell, `esptool` works but full `idf.py` build is blocked by host Python/Windows provider failures (`_overlapped` / WinError 10106). The user's normal IDF PowerShell Environment should be used for full `idf.py build flash monitor`.
- `firmware/doctor.bat` runs the v5.5.4 IDF profile, builds, flashes `COM5`, starts monitor, and writes logs under `logs/`.
- `firmware/monitor.bat` runs monitor only and writes logs under `logs/`.
- `firmware/flash-app.bat` flashes only `firmware/build/stack-chan.bin` to app slot `0x20000` using `esptool`; it does not erase NVS, assets, or bootloader.
- `tools/reset_config.bat` erases only the NVS partition at `0x9000` / `0x4000`, forcing Wi-Fi/app provisioning to start over without touching firmware or assets.
- `server-xz/` defaults to `http://192.168.0.250:8003` and handles both `/xiaozhi/ota/` and `/xiaozhi/v1/ota` so it matches the patched firmware default OTA URL.
- `server-xz/` serves a local dashboard at `http://192.168.0.250:8003/` for provider URL/key, model, voice, agent name, and system prompt settings. It persists to ignored local file `server-xz/config.local.json` and includes an OpenAI defaults preset for the first end-to-end provider path.
- `xcodebuild` is not on PATH in this shell, so iOS build was not attempted.

## First Fix Order

1. Replace hard-coded app/server firmware URLs with configurable settings or provisioning.
2. Decide whether the local Go backend is a development relay or production service; then clean DB/file-upload/runtime-state behavior accordingly.
3. Sanitize backend upload path handling.
4. Add WebSocket protocol integration tests around app-to-device routing.
5. Set up ESP-IDF and validate firmware build.
6. Validate iOS build in Xcode/macOS environment.
