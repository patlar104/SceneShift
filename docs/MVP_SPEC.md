# SceneShift MVP Specification

This document defines the first usable version of SceneShift. The MVP proves the core loop: scan one room, correct the result, edit a layout, validate placements, and save locally.

## Goals

- Capture a single room with RoomPlan and ARKit
- Represent walls, openings, and objects in an editable local model
- Let users correct detection mistakes before trusting the layout
- Move and rotate objects in a top-down editor
- Warn about collisions and blocked doorways
- Persist rooms and layouts on device only

## In scope

### One-room scanning

- Start, finish, and cancel a RoomPlan capture session
- Guide the user through scanning a single room
- Handle interruptions and permission failures without crashing
- Convert scan output into SceneShift room and object models

### RoomPlan and ARKit capture

- Use Apple RoomPlan for structured room capture
- Use ARKit as required by RoomPlan and device capabilities
- Check runtime support before offering scanning
- Surface unsupported-device and permission-denied states clearly

### Simple object bounding boxes

- Represent detected objects with axis-aligned or oriented bounding boxes
- Store dimensions, position, rotation, category, and confidence
- Keep geometry simple enough for editing and validation

### Manual correction

- Rename objects
- Edit categories
- Correct dimensions
- Mark objects as movable, fixed, or excluded
- Remove false detections
- Add missed objects manually

### Object states

- **Movable**: user may reposition and rotate the object in the layout editor
- **Fixed**: object stays in place unless the user explicitly changes its state
- **Excluded**: object is omitted from layout editing and suggestions while remaining available for correction history if needed

### Top-down layout editing

- Show room boundaries and openings from above
- Select objects
- Drag movable objects
- Rotate movable objects
- Optionally show measurements
- Keep fixed objects from moving accidentally

### Collision and doorway warnings

- Detect object overlaps
- Detect objects that leave the room boundary
- Warn when doorways are blocked or reduced below usable clearance
- Present warnings visually and textually
- Allow non-critical warnings to be overridden intentionally

### Saved layouts

- Save the original scanned arrangement
- Save one or more alternate layouts for the same room
- Reload saved rooms and layouts after app relaunch
- Avoid destroying saved layouts during restore or suggestion flows

### Undo and reset

- Undo and redo move and rotation operations
- Restore the original scanned arrangement
- Keep restore-original separate from deleting saved alternate layouts

### Local-only storage

- Persist room data on device
- Require no account
- Upload nothing by default
- Support deleting one room or all local SceneShift data

### Rescanning and reconciliation

- Allow a room to be rescanned
- Reconcile new scan results with existing objects where practical
- Preserve manual user corrections whenever reconciliation can do so safely
- Handle incompatible or corrupt persisted data without crashing

## Out of scope for MVP

The following are intentionally deferred:

- Cloud sync, accounts, or multi-device sharing
- Multi-room projects
- Furniture product catalogs or shopping integrations
- Photorealistic rendering or material editing
- Full interior-design automation
- Natural-language layout requests
- Accessibility scoring as a finished product feature
- Storage-optimization recommendations
- Moving or renovation workflows
- Apple Vision Pro / visionOS support
- Collaborative editing
- Automatic purchase, shipping, or contractor integrations
- Backend services and telemetry that depend on room geometry uploads

## MVP acceptance summary

The MVP is complete when a user on a supported device can:

1. Scan one room
2. Correct object names, categories, dimensions, and movable states
3. Edit a top-down layout with move, rotate, undo, redo, and restore-original
4. See collision and doorway warnings
5. Save and reopen the room locally
6. Delete the room and confirm related local data is removed

## Related documents

- [VISION.md](VISION.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [DATA_MODEL.md](DATA_MODEL.md)
- [PRIVACY.md](PRIVACY.md)
- [ROADMAP.md](ROADMAP.md)
