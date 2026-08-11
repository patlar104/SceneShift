# SceneShift Copilot Instructions

SceneShift is a Swift and SwiftUI Apple-platform project for intelligent spatial planning. It uses RoomPlan, ARKit, and RealityKit to scan rooms, correct detected objects, edit layouts, and validate placements.

## Platform and tooling

- Treat SceneShift as an Apple-platform app. Prefer Swift, SwiftUI, and native Apple frameworks.
- RoomPlan, ARKit, and RealityKit require Apple tooling. Do not treat Linux results as successful iOS build verification.
- Code must remain compatible with the selected deployment target once that target is documented in the Xcode project.
- Do not invent unsupported Apple APIs, symbols, capability keys, or framework behaviors.
- Claim build success only when confirmed by Xcode or macOS CI.

## Product and privacy constraints

- Privacy and local-only storage are required for the MVP.
- Do not add accounts, cloud sync, or default uploads.
- Keep sensitive room geometry out of diagnostic logs.
- Preserve deletion paths for individual rooms and all local data.

## Implementation guidance

- Inspect existing repository docs and structure before changing architecture.
- Keep new code modular and testable.
- Prefer small, reviewable changes over broad rewrites.
- Add unit tests for non-UI logic such as model mapping, persistence, validation, and suggestion ranking.
- Do not create duplicate app entry points.
- Do not modify Xcode project files blindly.
- Avoid introducing package dependencies unless they are clearly needed and approved by the project direction.

## Scanning and layout behavior

- Prefer RoomPlan and ARKit for capture rather than custom reconstruction pipelines in the MVP.
- Preserve manual user corrections during rescan reconciliation whenever safely possible.
- Fixed objects must remain fixed unless the user explicitly changes their state.
- Validation warnings should be understandable in both visual and textual forms.

## Verification rules

- Linux compilation or partial checks are not proof that the iOS app builds.
- Do not claim hardware, LiDAR, camera, or RoomPlan validation without testing on a supported Apple device or reporting the limitation clearly.
- Until the Xcode project exists, do not invent scheme names, bundle identifiers, entitlements, or CI destinations.

## Source of truth

Read these documents before substantial work:

- `docs/VISION.md`
- `docs/MVP_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/DATA_MODEL.md`
- `docs/PRIVACY.md`
- `docs/ROADMAP.md`
- `AGENTS.md`
