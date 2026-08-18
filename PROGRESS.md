# SceneShift progress

Living checklist for local and cloud agent handoff. Update this file at the **end of every task** before push.

## Current

- Task: 2 complete — waiting for user approval before Task 3
- Branch: feat/task-2-scanstore
- Last cloud agent: none
- Blockers: none
- Fixture: full `CapturedRoom` JSON round-trip waits for `SceneShiftTests/Fixtures/sample.room` from Task 3 device test. Task 2 tests index CRUD + stubbed room file I/O via injectable `ScanStore(directory:)`.

## Completed

- [x] Task 0 — spec + handoff files + workspace config + gated CI
- [x] Task 1 — Xcode SwiftUI project shell (iOS 17, RoomPlan linked, Info.plist)
- [x] Task 2 — ScanStore + SavedScan with XCTest round-trip tests

## Pending

- [ ] Task 3 — RoomPlan scan flow (RoomCaptureRepresentable, ScanSessionView, LiDAR guard)
- [ ] Task 4 — Quick Look preview, USDZ export, share sheet, delete from library
- [ ] Task 5 — `scripts/` package: local + cloud Cursor SDK CLIs
- [ ] Task 6 — README polish, empty states, user-visible errors, device provisioning docs
- [ ] Task 7 — Privacy manifest, app icon/launch screen, rename scans, storage awareness, scan lifecycle UX
- [ ] Task 8 — Scan details from CapturedRoom parametric data (no custom API)
