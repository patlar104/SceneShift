# SceneShift MVP Design Spec

**Date:** 2026-08-18  
**Status:** Approved for Task 0 handoff; implementation starts at Task 1 after user approval  
**Source plan:** [2026-08-18-sceneshift-bootstrap.md](../plans/2026-08-18-sceneshift-bootstrap.md)  
**Plan review:** [2026-08-18-sceneshift-plan-review.md](../reviews/2026-08-18-sceneshift-plan-review.md)

## Goal

Ship a LiDAR-capable native iOS app that scans a room, saves the capture locally, previews it, and exports/shares USDZ. No custom HTTP backend, no third-party scan SDKs, no custom spatial mesh pipeline.

## Architecture

```
SwiftUI (Home → Scan → Preview/Details)
    └── RoomPlan (RoomCaptureView → CapturedRoom)
            ├── ScanStore (Application Support/Scans/, Codable JSON + optional cached USDZ)
            ├── Quick Look (QLPreviewController) for preview
            └── CapturedRoom.export → USDZ → share sheet
```

Dev-only (not app runtime): `scripts/` TypeScript package using `@cursor/sdk` (local `Agent.create` + cloud `autoCreatePR`) for agent automation.

**MVP SwiftPM shape:** Xcode `.xcodeproj` app linking **system frameworks** (`RoomPlan`, `ARKit`). No root `Package.swift` until a shared Swift module is extracted.

### Runtime components (Tasks 1–4, 8)

| Piece | Responsibility |
|-------|----------------|
| `SceneShiftApp` | SwiftUI app lifecycle |
| `HomeView` | Scan library, New Scan, empty state |
| `RoomCaptureRepresentable` | `UIViewRepresentable` over `RoomCaptureView` + `RoomCaptureViewDelegate` |
| `ScanSessionView` | Full-screen scan, name prompt, interruption Resume/Discard |
| `ScanStore` / `SavedScan` | Local persist, rename, delete, file size, USDZ export |
| `RoomPreviewView` | Quick Look wrapper |
| `ScanDetailView` | Parametric walls/objects + dimensions + confidence |

### Explicitly not in runtime

- FastAPI, Vapor, CloudKit, auth, React/Vite frontend
- Custom AR overlay / homemade coaching copy (`RoomCaptureView` already coaches)
- Competitor SDKs (Matterport, Polycam, magicplan, Canvas, CubiCasa)

## Constraints

- **Platform:** iOS native only for v1. Scanning requires LiDAR (iPhone 12 Pro+ / iPad Pro 2020+).
- **Deployment target:** iOS 17.0.
- **On-device only:** No custom HTTP/REST/GraphQL backend, auth, or cloud sync in this milestone.
- **Frameworks over custom code:** RoomPlan for scan + export + coaching + dimensions; Quick Look for preview.
- **iOS deps:** Swift Package Manager only — no CocoaPods, no Carthage dependencies.
- **YAGNI:** Only create directories/files listed in the current task.
- **Dev scripts:** Node **22.13+**, **npm**, TypeScript ESM/`NodeNext`, **tsx**, `@cursor/sdk` **pinned** (not `latest`). **Not Bun.**
- **Never commit** `CURSOR_API_KEY` or `scripts/.env`.
- **Do not vendor-integrate** Matterport, Polycam, magicplan, Canvas, CubiCasa, Cesium, Omniverse, BIM/IFC APIs.

## Official reference documentation (required reading)

Implementation must follow these primary sources — not blog posts or pretrained assumptions.

### 1. Swift language & ecosystem — [swift.org/documentation](https://www.swift.org/documentation/)

| Topic | Official doc | How SceneShift uses it |
|-------|--------------|------------------------|
| Language & naming | [The Swift Programming Language](https://www.swift.org/documentation/) | All Swift code |
| Public API style | [API Design Guidelines](https://www.swift.org/documentation/) | `ScanStore`, `SavedScan`, view names |
| Dependencies | [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/) | iOS deps via Xcode/SPM; **no CocoaPods** |
| Creating packages | [Creating a Swift package](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/creatingswiftpackage) | Later: extract shared modules |
| Tests | XCTest | `SceneShiftTests/` |
| Concurrency | [Enabling Complete Concurrency Checking](https://www.swift.org/documentation/) | When moving to Swift 6 |
| Server (later) | [Swift on Server](https://www.swift.org/documentation/) | **Vapor** if backend stays Swift — not FastAPI |

**MVP:** no root `Package.swift`. System frameworks only.

### 2. RoomPlan — [developer.apple.com/documentation/roomplan](https://developer.apple.com/documentation/roomplan)

| Plan task | RoomPlan doc | API |
|-----------|--------------|-----|
| Task 3 scan UI | [Create a 3D model…](https://developer.apple.com/documentation/roomplan/create-a-3d-model-of-an-interior-room-by-guiding-the-user-through-an-ar-experience), [`RoomCaptureView`](https://developer.apple.com/documentation/roomplan/roomcaptureview) | Framework scan view + built-in instructions |
| Task 2 persist | [`CapturedRoom`](https://developer.apple.com/documentation/roomplan/capturedroom) (Codable) | encode/decode to disk |
| Task 4 export | [`USDExportOptions`](https://developer.apple.com/documentation/roomplan/capturedroom/usdexportoptions) | USDZ for share/preview |
| Task 8 dimensions | [Access the captured results](https://developer.apple.com/documentation/roomplan#Access-the-captured-results) | `Surface`/`Object` dimensions + confidence |
| Defer multi-room | [`StructureBuilder`](https://developer.apple.com/documentation/roomplan/structurebuilder) | After single-room MVP |

**Platform:** capture requires iOS/iPadOS LiDAR. Mac Catalyst can encode/decode/export `CapturedRoom` but cannot scan.

**Coaching:** stay on `RoomCaptureView`; do not invent custom lighting/speed copy. Custom `Instruction` handling only if switching to `RoomCaptureSession`.

**Known RoomPlan limits (document in README; do not “fix” with custom code):**

- Best for ~30×30 ft residential rooms; lighting ≥ ~50 lux; avoid scans longer than ~5 minutes (thermal/drift) — WWDC22 10127
- Rectangular simplification; limited object set; reported ~±5 cm wall drift
- Multi-room / ~2,000 sq ft structure merge is later (`StructureBuilder`)

### 3. FastAPI full-stack template — **DO NOT CLONE**

Template: [github.com/fastapi/full-stack-fastapi-template](https://github.com/fastapi/full-stack-fastapi-template)

That template is a **web app** (FastAPI + React + PostgreSQL + JWT + Docker Compose + Playwright). SceneShift v1 is a **native iOS app with no web client and no backend**.

| Template includes | SceneShift MVP | Verdict |
|-------------------|----------------|---------|
| FastAPI + SQLModel + PostgreSQL | No backend yet | **Defer** |
| React + Vite + Tailwind | iOS is the UI | **Reject** |
| JWT auth | No accounts yet | **Defer** |
| Docker Compose + Traefik | No server yet | **Defer** |

**Wrong move:** adding `backend/`, `frontend/`, `compose.yml`, `pyproject.toml`, or `bun.lock` from the FastAPI template to this repo.

**Phase 2+ only:** if product needs Python server-side ML **and** a web admin, use the template in a **separate repo** (or `backend/` only, strip `frontend/`). Prefer [Vapor](https://www.swift.org/documentation/) if the team stays Swift.

### 4. Cursor SDK (dev scripts only) — [cursor.com/docs/sdk/typescript](https://cursor.com/docs/sdk/typescript)

Separate from FastAPI. Node 22.13+, npm, `scripts/` package. See plan Task 5. Never treat SDK scripts as a production API server.

## Defer list (do not scaffold now)

- Custom HTTP API (Vapor / FastAPI / Node)
- CloudKit / iCloud Documents (50 MB `CKAsset` cap is too small for many USDZ scans; metadata-only sync later)
- Auth, user accounts, StoreKit
- Third-party scan/cloud SDKs
- Custom LiDAR point-cloud processing / Object Capture (`PhotogrammetrySession`)
- Furniture layout optimization; Apple Foundation Models (`LanguageModelSession`) — iOS 26+, Apple Intelligence devices
- Multi-room merge (`StructureBuilder` → `CapturedStructure`) until single-room works
- 2D CAD/DXF/BIM export
- macOS, visionOS, Android, cross-platform
- `BGTaskScheduler` large-export backgrounding until export is slow on device
- RealityKit in-app viewer (Quick Look is enough for MVP)
- Unity / Unreal / React Native / Flutter RoomPlan plugins
- XCUITest full suite (RoomPlan needs hardware)
- Xcode Cloud, fastlane
- Root thin `package.json` unless the user wants `npm run review` from repo root
- `.cursor/hooks.json` unless requested

## Verification split

| Label | Meaning | Who |
|-------|---------|-----|
| `[cloud-verify]` | `xcodebuild test` on simulator / CI; `scripts` typecheck | Agent + GitHub Actions |
| `[device-only]` | Live LiDAR scan, signing, golden `CapturedRoom` fixture | Human on physical iPhone |

Agents **must not block** PRs waiting for LiDAR hardware.

## Risk register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Apple Developer signing / device trust | First device run blocked | Document provisioning in README (Task 1); human-only; agents do not wait |
| No LiDAR in CI / cloud VM / simulator | Scan integration untestable in `[cloud-verify]` | LiDAR guard in UI; `[device-only]` checklist; golden fixture from one real scan |
| `CapturedRoom` XCTest without a real fixture | Round-trip tests incomplete | Task 2: index CRUD without full decode if needed; Task 3 device test commits `SceneShiftTests/Fixtures/sample.room` |
| Large USDZ disk use | Export fails; storage fills | `ScanStore.fileSize`; disk-full alert on export; do not delete temp USDZ until share completes |
| RoomPlan behavior skew (iOS 17 vs 18) | Capture/export API differences | Deployment target iOS 17; follow current Apple docs; keep coaching on `RoomCaptureView` |
| Simulator destination name (`iPhone 16`) missing | CI `xcodebuild` fails | Prefer `platform=iOS Simulator,OS=latest,name=iPhone 16`; fallback via `xcodebuild -showdestinations` (see `AGENTS.md`) |
| CI vs task ordering | Empty-repo CI red before Tasks 1 and 5 | Jobs gated on `SceneShift.xcodeproj` and `scripts/package.json` |
| GitHub remote / `SCENESHIFT_REPO_URL` | Cloud scripts cannot dispatch | Task 0 push establishes remote; Task 5 `.env.example` uses the real URL |
| CloudKit mistaken for USDZ sync | Data loss / failed uploads | Spec: 50 MB asset cap; do not use CloudKit for 3D files |
| Agent drift into FastAPI/Bun/CocoaPods | Wrong stack | `AGENTS.md` + always-apply Cursor rule + this spec |
| `RoomCaptureViewDelegate` NSCoding | Compile failure | Coordinator implements `encode(with:)` and `init?(coder:)` (Task 3) |

## Target layout (full plan; only Task 0 files exist now)

See the implementation plan. Task 0 creates handoff docs, workspace config, Cursor rules, and gated CI. **Do not** create `SceneShift.xcodeproj`, Swift sources, or `scripts/` in Task 0.

## Success criteria (MVP done)

- Scan a room on a LiDAR iPhone, save locally, preview USDZ, share
- `[cloud-verify]` green on `main` (tests + scripts typecheck)
- `PROGRESS.md` shows Tasks 0–8 complete
- README documents device requirements and (after Task 5) dev scripts
