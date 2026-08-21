# SceneShift progress

Living checklist for local and cloud agent handoff. Update this file at the **end of every task** before push.

## Current

- Task: 4 complete (walkthrough preview + exclusive 1-finger look / 2-finger strafe) — waiting for user approval before Task 5
- Branch: feat/task-4-preview-export
- Last cloud agent: none
- Blockers: none — `[device-only]` preview/share/rename/delete/disk-full is for the human; do not block merge. Re-verify on device: one-finger drag looks without sliding; two-finger slides; pinch dollies; Reset; spinner still dismisses; share still sends USDZ.
- Fixture: full `CapturedRoom` JSON round-trip still waits for `SceneShiftTests/Fixtures/sample.room`. Export one real scan during a device test. Do not invent JSON.
- Signing: `DEVELOPMENT_TEAM = LX83XRP475` is in `project.pbxproj` (Automatic, bundle `com.sceneshift.app`). Not xcuserdata-only.

## Completed

- [x] Task 0 — spec + handoff files + workspace config + gated CI
- [x] Task 1 — Xcode SwiftUI project shell (iOS 17, RoomPlan linked, Info.plist)
- [x] Task 2 — ScanStore + SavedScan with XCTest round-trip tests
- [x] Task 3 — RoomPlan scan flow (RoomCaptureRepresentable, ScanSessionView, LiDAR guard)
- [x] Task 4 — RealityKit walkthrough preview, USDZ export, share sheet, delete/rename from library

## Pending

- [ ] Task 5 — `scripts/` package: local + cloud Cursor SDK CLIs
- [ ] Task 6 — README polish, empty states, user-visible errors, device provisioning docs
- [ ] Task 7 — Privacy manifest, app icon/launch screen, rename scans, storage awareness, scan lifecycle UX
- [ ] Task 8 — Scan details from CapturedRoom parametric data (no custom API)

## [device-only] Task 3 checklist (human on LiDAR iPhone)

1. Open `SceneShift.xcodeproj`, select a Team under Signing & Capabilities, run on a LiDAR iPhone (12 Pro+ / iPad Pro 2020+).
2. Confirm Home shows empty state, tap **New Scan**, complete a room capture (RoomPlan coaching is built-in).
3. Tap **Done**, name the scan, Save — confirm the name appears in the Home list.
4. Background the app mid-scan: **Resume** should restart capture; **Discard** should leave without saving.
5. Optional: stay near ~3 minutes and confirm the “Finish early” thermal/drift hint.
6. Export that capture’s `{uuid}.room` from the device (Application Support/Scans/) into `SceneShiftTests/Fixtures/sample.room` in a follow-up commit so Task 2 can add a real `CapturedRoom` decode round-trip. Do not invent fixture JSON.

## [device-only] Task 4 checklist (human on LiDAR iPhone)

1. Open a saved scan from Home — in-app RealityKit preview should allow look (drag), ground pan (two-finger), and dolly (pinch). Share still sends the USDZ (Quick Look/AirDrop remain orbit-style).
2. Confirm each list row shows a formatted file size (e.g. "12.4 MB").
3. Share the USDZ via AirDrop or Files. Cached USDZ stays on disk until you delete the scan.
4. Rename via leading swipe or context menu; swipe-to-delete removes the scan.
5. Disk-full: if export cannot write, the alert **Not enough storage to export scan** should appear (do not expect this on a normal device with free space).
