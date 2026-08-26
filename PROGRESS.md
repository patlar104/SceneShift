# SceneShift progress

Living checklist for local and cloud agent handoff. Update this file at the **end of every task** before push.

## Current

- Task: 3 complete — waiting for user approval before Task 4
- Branch: feat/task-3-room-scan
- Last cloud agent: none
- Blockers: none — `[device-only]` LiDAR scan is for the human; do not block merge
- Fixture: full `CapturedRoom` JSON round-trip still waits for `SceneShiftTests/Fixtures/sample.room`. Export one real scan during the Task 3 device test (see checklist below). Do not invent JSON.

## Completed

- [x] Task 0 — spec + handoff files + workspace config + gated CI
- [x] Task 1 — Xcode SwiftUI project shell (iOS 17, RoomPlan linked, Info.plist)
- [x] Task 2 — ScanStore + SavedScan with XCTest round-trip tests
- [x] Task 3 — RoomPlan scan flow (RoomCaptureRepresentable, ScanSessionView, LiDAR guard)

## Pending

- [ ] Task 4 — Quick Look preview, USDZ export, share sheet, delete from library
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
