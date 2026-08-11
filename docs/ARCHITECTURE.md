# SceneShift Architecture

This document describes the proposed app structure before the Xcode project exists. Paths, targets, and module boundaries should be adapted once the real project structure is available. Prefer small, testable modules over premature abstraction.

## Design principles

- Privacy-first and local-only for the MVP
- Prefer native Apple frameworks: SwiftUI, RoomPlan, ARKit, RealityKit, and Foundation
- Keep capture, domain models, persistence, editing, validation, and suggestion logic separable
- Avoid inventing unsupported Apple APIs
- Keep architecture flexible until the Xcode project lands

## Suggested areas

### App shell and navigation

Owns app launch, root navigation, unsupported-device states, permission recovery, and high-level routing between rooms, scanning, correction, and layout editing.

Responsibilities:

- Present the room list or empty state
- Route into scan, correction, and editor flows
- Surface global errors and recovery instructions
- Avoid duplicate app entry points

### Room scanning

Owns RoomPlan session lifecycle and scan guidance UI.

Responsibilities:

- Check RoomPlan and camera support at runtime
- Start, finish, cancel, and interrupt capture cleanly
- Present scanning guidance and progress
- Hand raw scan output to room processing
- Map framework errors into user-visible messages

### Room processing

Converts RoomPlan and ARKit output into SceneShift domain models.

Responsibilities:

- Normalize walls, doors, windows, openings, and objects
- Assign stable identifiers where possible
- Record confidence and detection source
- Produce an original arrangement snapshot
- Prepare data for persistence and editing

### Room and object models

Defines the in-memory domain types used across the app.

Responsibilities:

- Represent rooms, objects, openings, layouts, and warnings
- Track movable, fixed, and excluded states
- Carry schema versioning for local persistence
- Remain independent of SwiftUI view state where practical

See [DATA_MODEL.md](DATA_MODEL.md) for the initial field-level expectations.

### Local persistence

Stores rooms and layouts on device only.

Responsibilities:

- Save and reload rooms after relaunch
- Version persisted schemas
- Handle corrupt or incompatible data safely
- Delete one room or all local data
- Avoid writing unnecessary camera frames

Exact storage technology can be chosen after the Xcode project exists. Candidates include Codable file storage, SwiftData, or Core Data. The MVP requirement is local-only durability, not a specific persistence stack.

### Layout editor

Provides the top-down interactive editing surface.

Responsibilities:

- Render room boundaries, openings, and objects
- Support selection, drag, and rotation for movable objects
- Prevent accidental movement of fixed objects
- Integrate undo, redo, and restore-original
- Display measurements when useful
- Feed proposed placements into validation

### Placement validation

Evaluates whether a layout is safe and usable enough for the MVP.

Responsibilities:

- Detect object overlaps
- Detect wall-boundary violations
- Warn about doorway clearance problems
- Warn about blocked or narrow walking paths
- Produce accessible visual and textual warnings
- Allow intentional override of non-critical warnings

### Layout suggestion engine

Generates simple rule-based alternatives after editing and validation exist.

Responsibilities:

- Keep fixed objects fixed
- Preserve door clearance
- Rank alternative layouts
- Explain suggestion reasoning in plain language
- Allow the user to reject or modify a suggestion

The first suggestion engine should stay rule-based and inspectable. Do not introduce cloud model dependencies into the MVP.

### Privacy and deletion controls

Implements the privacy requirements from [PRIVACY.md](PRIVACY.md).

Responsibilities:

- Keep default behavior local-only and account-free
- Provide room-level deletion
- Provide full local data deletion
- Keep sensitive geometry out of diagnostic logs
- Make any future upload path explicit and opt-in

## Proposed dependency direction

```text
App Shell
  ├── Room Scanning ──► Room Processing ──► Room/Object Models
  ├── Manual Correction ───────────────────► Room/Object Models
  ├── Layout Editor ──► Placement Validation
  │                 └──► Layout Suggestion Engine
  └── Local Persistence ◄── Room/Object Models
```

Views should depend on models and services. Capture frameworks should not leak into persistence or suggestion logic more than necessary.

## Testing expectations

- Unit-test non-UI logic: model mapping, persistence versioning, validation, suggestion ranking, and reconciliation
- UI tests can cover navigation and critical flows once the Xcode UI-test target exists
- Do not treat Linux compilation as successful iOS verification
- Only claim device or LiDAR validation after testing on a supported Apple device

## Deferred until the Xcode project exists

Do not create these prematurely:

- Swift source files
- Xcode build settings
- Entitlements and app capabilities
- Package dependencies
- macOS CI workflows with exact scheme names
- Simulator destinations
- Bundle identifier references
- App target paths

Those details must follow the real project structure.
