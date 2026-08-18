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
