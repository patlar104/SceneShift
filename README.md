# SceneShift

spatial planning platform that uses LiDAR, AR, and on-device intelligence to understand, visualize, and optimize real-world environments.

Agent onboarding: see [AGENTS.md](AGENTS.md) and [PROGRESS.md](PROGRESS.md).

## Requirements

- **Xcode 15+** (this repo was scaffolded with Xcode 26.6)
- **iOS 17.0+** deployment target
- **LiDAR hardware** for scanning: iPhone 12 Pro or later, or iPad Pro (2020) or later
- The iOS Simulator can build and run the SwiftUI shell, but **cannot scan** rooms

Bundle ID: `com.sceneshift.app`

## Open the project

```bash
open SceneShift.xcodeproj
```

No CocoaPods. No root `Package.swift`. RoomPlan and ARKit are linked as Apple system frameworks.

## Device provisioning `[device-only]`

RoomPlan scanning requires a physical LiDAR device. Agents do not block PRs on this.

1. Sign in with an **Apple Developer account** (free or paid) in Xcode → Settings → Accounts
2. Open the project → target **SceneShift** → **Signing & Capabilities** → select your **Team**
3. Connect the iPhone via USB, unlock it, and **Trust This Computer**
4. Choose the device as the run destination and press **Run** (Cmd+R)

The simulator destination used for `[cloud-verify]` cannot perform a RoomPlan capture.

## Build and test (simulator) `[cloud-verify]`

Preferred destination (from `AGENTS.md`):

```bash
xcodebuild test \
  -scheme SceneShift \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16'
```

If that simulator is missing, list destinations and pick an available iPhone:

```bash
xcodebuild -scheme SceneShift -showdestinations
```

This Mac used `platform=iOS Simulator,OS=latest,name=iPhone 17` (iOS 26.5) because iPhone 16 was not installed. CI uses the same fallback (iPhone 16 → iPhone 17 → first available iPhone).
