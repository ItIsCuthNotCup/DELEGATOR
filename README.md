# Delegator

A native SwiftUI iOS app that serves as a mission control dashboard for [OpenClaw](https://github.com/nichochar/openclaw) AI agents. Connect to your self-hosted OpenClaw Gateway and monitor agent sessions, costs, and activity in real time.

## Features

- **Dashboard** — Agent roster, token spend, gateway health, model routing
- **Activity Feed** — Real-time WebSocket events from your agents
- **Cron Jobs** — View and trigger scheduled jobs
- **Emergency Stop** — Kill a runaway agent instantly
- **QR Connect** — Scan a QR code to connect to your gateway
- **Dark Glass UI** — Near-black translucent panels with a yellow accent

## Requirements

- iOS 17+
- Xcode 16+
- An OpenClaw Gateway instance (self-hosted)

## Setup

1. Clone and open in Xcode:
   ```bash
   git clone https://github.com/ItIsCuthNotCup/DELEGATOR.git
   cd DELEGATOR
   open Delegator.xcodeproj
   ```

2. Build and run on a simulator or device (Cmd+R).

3. Enter your gateway URL and token on the connect screen. If your gateway is on a Tailscale network, use the Tailscale IP (e.g. `http://100.x.x.x:18789`).

## Architecture

- **SwiftUI** with `@Observable` (Swift 6)
- **No third-party dependencies** — pure Apple frameworks
- **Keychain** for credential storage
- **WebSocket** for real-time events, HTTP polling as fallback
- All design tokens in `Theme.swift`

## Security

- Credentials are stored in the iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- No secrets, tokens, or API keys are hardcoded in the source
- `NSAllowsArbitraryLoads` is enabled to support self-hosted gateways on local networks over HTTP. The app warns when connecting over unencrypted HTTP to non-localhost addresses
- Debug logging is compiled out in Release builds (`#if DEBUG`)

## License

MIT — see [LICENSE](LICENSE).
