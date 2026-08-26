# SceneShift Plan Review (2026-08-18)

Copied from the implementation plan for cloud handoff (agents read the repo, not `~/.cursor/plans/`).

> **Review method:** `requesting-code-review` skill pattern — dispatched to review subagent; interrupted before completion. Review completed inline and saved here + Task 0 `docs/superpowers/reviews/` on execution.
>
> **Verdict:** **Ready to execute with fixes** (patches applied below in this plan).
>
> **Post-review note:** In-app preview switched from Quick Look to a RealityKit non-AR walkthrough after Quick Look’s orbit camera proved a poor room walkthrough; the USDZ share path is unchanged (AirDrop/Files receivers may still open the file in system Quick Look).

## Strengths

- **Requirements alignment:** Delivers LiDAR scan → local save → RealityKit walkthrough preview → USDZ share without backend, auth, or third-party scan SDKs — matches stated MVP.
- **Research-backed stack:** RoomPlan + SwiftUI + RealityKit walkthrough is the correct first-party path; explicit rejection of FastAPI template clone, CocoaPods, Bun, and competitor SDKs reduces agent drift.
- **Cloud handoff surface:** `AGENTS.md`, `PROGRESS.md`, committed plan copy, branch-per-task, `[cloud-verify]` / `[device-only]` split — strong foundation for Cursor Cloud Agents.
- **API landscape section:** Documents RoomPlan limits, coaching via `RoomCaptureView`, CloudKit 50 MB caveat, and deferred Foundation Models — prevents premature “fix with custom code.”
- **Task interfaces:** `ScanStore` / `SavedScan` signatures are concrete; Task 8 correctly scopes to parametric list, not 2D CAD.
- **TDD where feasible:** Task 2 follows red-green on simulator-friendly persistence; device-only integration called out explicitly.

## Issues

### Critical (fixed in this plan revision)

1. **CI vs task ordering deadlock**
   - **Issue:** Task 0 CI ran `scripts typecheck` but `scripts/` is not created until Task 5; `xcodebuild test` fails before Task 1.
   - **Fix applied:** CI jobs gated by path existence; scripts job documented as Task 5+ only.

2. **Wrong delegate type in Task 3**
   - **Issue:** Step 1 referenced `RoomCaptureSessionDelegate` while snippet used `RoomCaptureViewDelegate` callbacks — agents would implement the wrong protocol.
   - **Fix applied:** Explicit `RoomCaptureViewDelegate`, `shouldPresent → true`, NSCoding stub note.

3. **HomeView creation missing**
   - **Issue:** Task 3 “Modify HomeView” but Task 1 only ships placeholder `Text("SceneShift")` — no file to modify.
   - **Fix applied:** Task 3 Step 4 now **creates** `HomeView.swift`.

### Important (address during execution)

1. **`RoomCaptureViewDelegate` requires `NSCoding`**
   - Coordinator must implement `encode(with:)` and `init?(coder:)` (can be minimal no-ops). Add during Task 3 implementation; link [RoomCaptureViewDelegate](https://developer.apple.com/documentation/roomplan/roomcaptureviewdelegate).

2. **`CapturedRoom` XCTest fixture**
   - Codable round-trip may need a real device-exported JSON fixture; plan note is correct but Task 2 should **commit a minimal fixture** from one real scan early (Task 3 device test) or split tests: index CRUD without full room decode until fixture exists.

3. **Task 5 after Task 0 CI expectation**
   - After Task 5, update CI to enable `scripts-check` job and verify in PR. Add to Task 5 Step 12 checklist.

4. **Simulator destination fragility**
   - `iPhone 16` may not exist on older Xcode. Prefer `platform=iOS Simulator,OS=latest,name=iPhone 16` with fallback documented in `AGENTS.md`, or use `xcodebuild -showdestinations` in CI setup step.

5. **GitHub remote prerequisite**
   - `SCENESHIFT_REPO_URL` is placeholder until user pushes. Task 0 Step 8 must confirm remote URL before Task 5 cloud scripts are smoke-tested.

6. **Subagent review gate**
   - Plan recommends subagent-driven development but does not mandate `requesting-code-review` after each task. **Process:** after each task PR, run review subagent or `npm run review` before merge.

### Minor

1. **Task 6 vs Task 7 overlap** — rename/fileSize UX appears in Tasks 4, 6, 7; acceptable but Task 6 empty-state could move to Task 3 HomeView stub.
2. **Root thin `package.json`** — optional; defer unless user wants `npm run review` from repo root.
3. **Sweetpad extension** — optional; document that CI/agents do not require it.
4. **Task 8 dimension formatting** — use `Measurement` / locale-aware units; `Surface.dimensions` is 3D — clarify which axes map to width×height in UI copy.

## Recommendations

- Add **Risk register** to design spec (Task 0): signing/provisioning friction, no LiDAR in CI, large USDZ disk use, RoomPlan version skew across iOS 17–18.
- Capture **one golden `CapturedRoom` JSON + USDZ** from device during Task 3 manual test; add to `SceneShiftTests/Fixtures/` for stable tests.
- After Task 0 push, verify cloud agent can read `docs/superpowers/reviews/` and `PROGRESS.md` without local `.cursor/plans/` cache.

## Assessment

**Ready to execute?** **With fixes** (critical patches incorporated above).

**Reasoning:** Plan is unusually thorough for a greenfield bootstrap and correctly centers RoomPlan. The interrupted subagent found no fundamental architecture flaws; remaining gaps are ordering/CI gating, delegate protocol details, and test fixture strategy — all addressable without rescoping MVP.
