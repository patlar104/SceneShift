# SceneShift

SceneShift is an intelligent spatial-planning app that scans real-world environments, understands objects and usable space, and helps users test changes before moving anything physically.

This repository currently contains the product and engineering foundation. The Xcode project will be added next.

## Documentation

| Document | Purpose |
| --- | --- |
| [docs/VISION.md](docs/VISION.md) | Long-term product purpose and future directions |
| [docs/MVP_SPEC.md](docs/MVP_SPEC.md) | First usable version requirements and out-of-scope items |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Proposed app structure before implementation |
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

1. Create and push the SceneShift Xcode project
2. Open the Phase 1–6 GitHub issues from `.github/ISSUE_DRAFTS/`
3. Add hardware checks and RoomPlan scanning
4. Add local persistence, correction, editing, validation, and suggestions
5. Add macOS CI once the real app target and scheme exist

## Intentionally deferred

Swift sources, entitlements, package dependencies, bundle identifier automation, and macOS CI scheme wiring wait until the Xcode project structure is in the repository.
