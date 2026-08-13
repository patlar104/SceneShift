# AGENTS.md

Guidance for coding agents working in the SceneShift repository.

## What SceneShift is

SceneShift is a privacy-first spatial-planning app for Apple platforms. It scans real rooms, helps users correct object detection, supports top-down layout editing, and warns about impractical placements. The MVP is local-only and focused on one room.

## Before you change code

1. Inspect the repository structure and docs first.
2. Read `docs/MVP_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, and `docs/PRIVACY.md`.
3. Prefer the existing direction over inventing a new architecture.
4. Keep changes narrowly scoped to the requested task.

## Project coordinates

- Open `sceneshift.xcworkspace` (references `SceneShift.xcodeproj`)
- Scheme: `SceneShift`
- Bundle identifier: `patrick.SceneShift`
- Deployment target: iOS 26.5
- App sources: `SceneShift/`
- Unit tests: `SceneShiftTests/`
- UI tests: `SceneShiftUITests/`
- App entry point: `SceneShift/SceneShiftApp.swift` (`@main`)

## Workspace and layout pitfalls

Keep these true so Xcode and agents do not break the project again:

- Do **not** delete `sceneshift.xcworkspace`. Prefer opening the workspace over the bare `.xcodeproj`.
- `sceneshift.xcworkspace/contents.xcworkspacedata` must reference the project with a non-empty location, for example:

```xml
<FileRef location = "group:SceneShift.xcodeproj">
```

  An empty value such as `location = "container:"` makes Xcode/xcodebuild treat the workspace as invalid.
- Keep app/test folders as siblings of `SceneShift.xcodeproj` at the repo root (`SceneShift/`, `SceneShiftTests/`, `SceneShiftUITests/`). Do not nest them under an extra wrapper folder.
- Commit `SceneShift.xcodeproj/xcshareddata/xcschemes/SceneShift.xcscheme`. Do not commit `xcuserdata/`.

## Agent sandbox vs local Xcode

- On this Mac, Xcode 26.6 and the iOS 26.5 Simulator runtime are installed. Simulators such as iPhone 17 Pro are available when tools run with full host access.
- The default Cursor agent sandbox cannot talk to `CoreSimulatorService` (`Connection refused` / “Unable to discover any Simulator runtimes”). That is a sandbox restriction, not a missing Simulator install.
- For agent builds: request unrestricted/`all` permissions, use `-derivedDataPath` inside the repo (for example `.derivedData/`, already gitignored), and prefer `generic/platform=iOS Simulator` when you only need compile verification.
- Do not claim “Simulator is not configured” solely because a sandboxed `simctl` call failed. Re-check with full permissions before concluding that.
- Booting or UI-driving a Simulator from the agent still needs full host access; RoomPlan/LiDAR still need a real device.

## Hard rules

- Do not create duplicate app entry points.
- Do not modify Xcode project files blindly.
- Do not invent unsupported Apple APIs.
- Do not introduce cloud dependencies into the MVP.
- Do not treat Linux results as successful iOS build verification.
- Do not claim hardware validation without testing on a supported device.
- Do not retain unnecessary camera frames or log sensitive room geometry.

## Command guardrails (when tools go wrong)

Treat failed shell/Xcode commands as **constrained**, not as permission to destroy and recreate.

### Forbidden without an explicit user ask

- `rm -rf` (or equivalent) on `sceneshift.xcworkspace`, `SceneShift.xcodeproj`, `SceneShift/`, `SceneShiftTests/`, or `SceneShiftUITests/`
- Recreating the workspace/project from scratch to “fix” a sandbox or `xcodebuild` error
- Emptying `contents.xcworkspacedata` or setting `location = "container:"`
- `git reset --hard`, `git clean -fdx`, force push, or history rewrite
- Deleting host Simulator devices/runtimes or global DerivedData as troubleshooting

### Required behavior instead

1. Prefer **in-place repairs** (edit the workspace FileRef, move folders back to the documented layout).
2. If the default sandbox blocks Simulator/`DerivedData`, request elevated/`all` permissions for that command only.
3. Keep agent builds inside the repo with `-derivedDataPath .derivedData`.
4. If Auto-review or policy blocks a destructive command, **stop and ask** — do not rephrase the same delete to sneak past it.
5. Scope every cleanup command to files the current task actually owns; refuse broad wipe commands.

Cursor also enforces this via [`.cursor/rules/command-guardrails.mdc`](.cursor/rules/command-guardrails.mdc).

## Implementation preferences

- Prefer native Apple frameworks: SwiftUI, RoomPlan, ARKit, RealityKit, and Foundation.
- Explain Apple framework assumptions when your change depends on them.
- Keep code modular and testable.
- Add tests for non-UI logic.
- Preserve manual user corrections during rescan logic.
- Keep fixed objects fixed unless the user explicitly changes state.
- Favor clear validation warnings over silent failures or silent overrides.

## Landed project guidance

The Xcode project is in the repository. Continue to:

- Avoid blind `project.pbxproj` edits; prefer Xcode or carefully reviewed, minimal changes
- Avoid inventing entitlements, capability keys, or Info.plist permission strings until a feature needs them
- Avoid inventing macOS CI destinations or workflow assumptions until CI is intentionally added
- Keep a single `@main` app entry point in `SceneShift/SceneShiftApp.swift`
- Add new Swift sources under the existing synchronized folders so Xcode picks them up

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
