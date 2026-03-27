# CLAUDE.md

This file provides guidance to Claude Code when working on this repository.

## Project

Delegator is a native SwiftUI iOS app (iOS 17+) that serves as a mission control dashboard
for OpenClaw AI agents. It connects to the user's self-hosted OpenClaw Gateway via
WebSocket and HTTP, displaying agent status, costs, cron jobs, and activity in real time.

## Commands

```bash
# Open in Xcode
open Delegator.xcodeproj

# Build from command line
xcodebuild -scheme Delegator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild -scheme Delegator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Architecture

- **SwiftUI** iOS 17+ with `@Observable` (not ObservableObject)
- **Single source of truth:** `AppState` is `@Observable`, `@MainActor`, injected at root
- **Networking:** `GatewayConnection` handles WebSocket (foreground) + HTTP (anytime)
- **Security:** All credentials in iOS Keychain via `KeychainManager`
- **Persistence:** SwiftData for cost history and cached state
- **No third-party dependencies.** Pure Apple frameworks only.

## Design System

All colors, fonts, and radii are in `Theme.swift`. Never hardcode colors — always use `Theme.*`.
The visual language is "dark glass" — near-black translucent panels on deep black backgrounds.
Signature accent: `Theme.accentYellow` (#FFD60A). Monospaced font for all data values.

See DELEGATOR-SPEC.md Section 6 for the complete design token reference.

## Key Patterns

- Every card uses `GlassCard` as its container
- Inner elements use `GlassTile`
- Buttons use `GlassButtonStyle`
- Tab navigation at root: Dashboard, Activity, Cron, Settings
- WebSocket auto-disconnects on background, reconnects on foreground
- HTTP `/tools/invoke` is used for all data fetching (not CLI)
- Emergency stop = `POST /hooks/agent` or WebSocket `chat.abort`

## Gateway API

The OpenClaw Gateway runs on port 18789. Auth via `Authorization: Bearer <token>`.
- `GET /health` — no auth, check if running
- `POST /tools/invoke` — call gateway tools (sessions_list, cron, status, etc.)
- `POST /v1/chat/completions` — OpenAI-compatible chat
- `POST /hooks/agent` — send message to agent
- `POST /hooks/wake` — trigger agent wake
- WebSocket `ws(s)://<host>:18789/` — real-time events
