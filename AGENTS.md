# SceneShift — Agent Guide

## Read first

1. [`PROGRESS.md`](PROGRESS.md) — current task
2. [`docs/superpowers/plans/2026-08-18-sceneshift-bootstrap.md`](docs/superpowers/plans/2026-08-18-sceneshift-bootstrap.md) — full plan
3. [`docs/superpowers/specs/2026-08-18-sceneshift-mvp-design.md`](docs/superpowers/specs/2026-08-18-sceneshift-mvp-design.md) — design spec
4. [`docs/superpowers/reviews/2026-08-18-sceneshift-plan-review.md`](docs/superpowers/reviews/2026-08-18-sceneshift-plan-review.md) — plan review / risks

## Stack

- iOS: Swift, SwiftUI, RoomPlan (https://developer.apple.com/documentation/roomplan)
- Swift: https://www.swift.org/documentation/
- SwiftPM: https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/ — **no CocoaPods**
- Dev scripts: Node 22.13+, npm, `scripts/` (NOT Bun)
- Do NOT scaffold: FastAPI template, `backend/`, `frontend/`, CocoaPods

## Official docs (required)

- Swift language & API Design Guidelines: https://www.swift.org/documentation/
- RoomPlan: https://developer.apple.com/documentation/roomplan
- Swift Package Manager: https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/
- FastAPI full-stack template: https://github.com/fastapi/full-stack-fastapi-template — **DO NOT CLONE** into this repo for MVP

## Constraints

- Native iOS only for v1; on-device; Apple first-party APIs
- SPM only (no CocoaPods, no Carthage deps)
- YAGNI: only files listed in the current plan task
- Never commit `CURSOR_API_KEY`
- Pin `@cursor/sdk`; do not use `latest`
- Do not start the next numbered task until the user approves (Task 0 → Task 1 is an explicit gate)

## Verification

- `[cloud-verify]`: `xcodebuild test` (CI) + `scripts` typecheck
- `[device-only]`: LiDAR scan — human runs on iPhone; do not block PR on this
- Simulator destination: `platform=iOS Simulator,OS=latest,name=iPhone 16`
  - If that device is missing on the runner or local Xcode, run `xcodebuild -scheme SceneShift -showdestinations` and pick an available iPhone simulator. Do not hard-fail the whole plan on a missing device name.

## Handoff

- One task per branch: `feat/task-N-name`
- Update `PROGRESS.md` before every push
- **Your playbook:** [`docs/superpowers/plans/2026-08-18-sceneshift-bootstrap.md`](docs/superpowers/plans/2026-08-18-sceneshift-bootstrap.md) → section **Recommended Execution Handoff**

## Current work

Read `PROGRESS.md` for the active task, branch, optional cloud agent id (`bc-…`), and blockers. Implement that task only.

## Learned User Preferences

- Use skills and official docs to verify APIs, frameworks, and tooling; do not rely on pretrained knowledge alone
- During audits or config work, preserve the existing working tree; do not reset, stash, clean, or discard unrelated user changes
- Do not commit machine-specific Xcode or editor settings (development team, physical device IDs, local LLDB or toolchain paths)
- SwiftLint (`.swiftlint.yml`) and Apple swift-format (`.swift-format`) are expected for local Swift quality; use Cursor/VS Code tasks **SwiftLint**, **Swift: Format**, and **Swift: Format lint**

## Learned Workspace Facts

- Shared `project.pbxproj` has no committed development team; configure device signing locally in Xcode (Signing & Capabilities)
- Omit `.cursor/environment.json` until both `scripts/package.json` and `scripts/package-lock.json` exist; do not leave a broken `npm ci` bootstrap
- `.cursor/cli.json` must follow the current Cursor CLI schema (`permissions` only; no unsupported top-level keys such as `attribution`)
- `.cursor/hooks/state/` is local agent state and is gitignored
- Project MCP server is `xcode-tools` via `xcrun mcpbridge` (enable Intelligence/MCP in Xcode with the project open)
- CI and local simulator tests prefer iPhone 16, then iPhone 17, then the first available iPhone from `xcodebuild -showdestinations`
- Do not commit USDZ binaries or files under `airdroped-tests/`
