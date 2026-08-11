# AGENTS.md

Guidance for coding agents working in the SceneShift repository.

## What SceneShift is

SceneShift is a privacy-first spatial-planning app for Apple platforms. It scans real rooms, helps users correct object detection, supports top-down layout editing, and warns about impractical placements. The MVP is local-only and focused on one room.

## Before you change code

1. Inspect the repository structure and docs first.
2. Read `docs/MVP_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, and `docs/PRIVACY.md`.
3. Prefer the existing direction over inventing a new architecture.
4. Keep changes narrowly scoped to the requested task.

## Hard rules

- Do not create duplicate app entry points.
- Do not modify Xcode project files blindly.
- Do not invent unsupported Apple APIs.
- Do not introduce cloud dependencies into the MVP.
- Do not treat Linux results as successful iOS build verification.
- Do not claim hardware validation without testing on a supported device.
- Do not retain unnecessary camera frames or log sensitive room geometry.

## Implementation preferences

- Prefer native Apple frameworks: SwiftUI, RoomPlan, ARKit, RealityKit, and Foundation.
- Explain Apple framework assumptions when your change depends on them.
- Keep code modular and testable.
- Add tests for non-UI logic.
- Preserve manual user corrections during rescan logic.
- Keep fixed objects fixed unless the user explicitly changes state.
- Favor clear validation warnings over silent failures or silent overrides.

## Until the Xcode project exists

Do not prematurely create:

- Swift source files
- Xcode build settings
- Entitlements
- App capabilities
- Package dependencies
- macOS CI workflows that assume exact scheme names
- Simulator destinations
- Bundle identifier references
- App target paths

This repository currently establishes documentation, templates, and issue structure so development can begin cleanly once the Xcode project is pushed.

## Pull requests and verification

- Summarize what changed and why.
- Link the related issue when one exists.
- State what testing was completed and what was not.
- Claim Xcode build success only when confirmed by Xcode or macOS CI.
- Call out privacy impact for any persistence, logging, or networking change.

## Useful references

- `.github/copilot-instructions.md`
- `docs/VISION.md`
- `docs/ROADMAP.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_DRAFTS/` for the initial MVP issue set
