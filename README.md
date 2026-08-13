# SceneShift

SceneShift is an intelligent spatial-planning app that scans real-world environments, understands objects and usable space, and helps users test changes before moving anything physically.

This repository includes product docs and the initial SwiftUI Xcode project.

## Open the app

Open [`sceneshift.xcworkspace`](sceneshift.xcworkspace) in Xcode (preferred). The workspace references [`SceneShift.xcodeproj`](SceneShift.xcodeproj).

Do not remove the workspace, and keep `sceneshift.xcworkspace/contents.xcworkspacedata` pointing at `SceneShift.xcodeproj` (never an empty `container:` location). App, unit-test, and UI-test folders must stay siblings of the `.xcodeproj` at the repo root.

| Setting | Value |
| --- | --- |
| Scheme | `SceneShift` |
| Bundle identifier | `patrick.SceneShift` |
| Deployment target | iOS 26.5 |
| Targets | `SceneShift`, `SceneShiftTests`, `SceneShiftUITests` |

App sources live in [`SceneShift/`](SceneShift/), unit tests in [`SceneShiftTests/`](SceneShiftTests/), and UI tests in [`SceneShiftUITests/`](SceneShiftUITests/).

## Documentation

| Document | Purpose |
| --- | --- |
| [docs/VISION.md](docs/VISION.md) | Long-term product purpose and future directions |
| [docs/MVP_SPEC.md](docs/MVP_SPEC.md) | First usable version requirements and out-of-scope items |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Proposed app structure |
| [docs/DATA_MODEL.md](docs/DATA_MODEL.md) | Initial room, object, layout, and warning data |
| [docs/PRIVACY.md](docs/PRIVACY.md) | Privacy-first and local-only MVP requirements |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Phased development plan |

## Agent guidance

- [AGENTS.md](AGENTS.md) for coding-agent rules
- [.github/copilot-instructions.md](.github/copilot-instructions.md) for GitHub Copilot

## Contribution templates

- Feature request: `.github/ISSUE_TEMPLATE/feature.md`
- Bug report: `.github/ISSUE_TEMPLATE/bug.md`
- Pull request checklist: `.github/PULL_REQUEST_TEMPLATE.md`
- Initial MVP issue drafts: `.github/ISSUE_DRAFTS/`

## What comes next

1. Open the remaining Phase 1–6 GitHub issues from `.github/ISSUE_DRAFTS/`
2. Add hardware and permission checks (issue draft 02)
3. Add basic RoomPlan scanning (issue draft 03)
4. Add local persistence, correction, editing, validation, and suggestions
5. Add macOS CI once entitlements and capability needs are settled

## Intentionally deferred

Entitlements, camera/LiDAR permission strings, package dependencies, and macOS CI remain deferred until the related MVP features need them.
