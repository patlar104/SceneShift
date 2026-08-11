# SceneShift Roadmap

This roadmap separates SceneShift development into practical phases. Later phases assume earlier foundations exist. Exact file paths and Xcode settings wait until the app project is in the repository.

## Phase 1: Repository and Xcode foundation

- Create the Xcode project
- Push project files to the repository
- Add basic app navigation
- Configure unit-test and UI-test targets
- Configure capability and permission checks
- Document the deployment target and bundle identifier

Outcome: a buildable SceneShift app shell ready for RoomPlan work.

## Phase 2: Room scanning

- Start RoomPlan capture
- Display scan guidance
- Convert scan output into internal models
- Save and reopen a room
- Handle cancel, interrupt, and error states

Outcome: a user can scan one room and reopen it locally.

## Phase 3: Manual correction

- Rename objects
- Edit categories
- Correct dimensions
- Mark objects fixed, movable, or excluded
- Add or remove objects manually
- Preserve corrections across save/reload

Outcome: users can trust the room model enough to edit layouts.

## Phase 4: Layout editor

- Top-down room view
- Select objects
- Move objects
- Rotate objects
- Undo and redo
- Restore original layout
- Keep fixed objects from moving accidentally

Outcome: users can try alternate arrangements without physical effort.

## Phase 5: Validation

- Object overlap detection
- Wall boundary validation
- Door clearance warnings
- Walkway warnings
- Accessible visual and textual warning presentation
- Override path for non-critical warnings

Outcome: edited layouts communicate practical problems before the user commits to them.

## Phase 6: Layout suggestions

- Generate simple rule-based layouts
- Rank layout alternatives
- Explain suggestion reasoning
- Keep fixed objects fixed
- Preserve door clearance
- Allow reject or modify flows

Outcome: SceneShift can propose useful starting points without cloud dependencies.

## After the MVP

Once Phases 1 through 6 are solid, revisit the longer-term ideas in [VISION.md](VISION.md):

- Accessibility analysis
- Storage optimization
- Multi-room planning
- Moving and renovation support
- Apple Vision Pro support
- Natural-language layout requests
- Shared projects

## Explicitly waiting on the Xcode project

Do not create these before the real project structure exists:

- Swift source files
- Xcode build settings
- Entitlements
- App capabilities
- Package dependencies
- macOS CI workflow with exact scheme names
- Simulator destinations
- Bundle identifier references in automation
- App target paths assumed by scripts

## Suggested issue sequencing

1. Create the SceneShift Xcode project
2. Add hardware and permission checks
3. Implement basic RoomPlan scanning
4. Define room and object models
5. Save and reload one room locally
6. Build the top-down layout editor
7. Add manual correction controls
8. Add undo, redo, and restore-original behavior
9. Add placement validation
10. Add first layout-suggestion prototype

Issue drafts for these work items live in `.github/ISSUE_DRAFTS/`.
