# SceneShift Data Model

This document defines the initial data expected for rooms, objects, layouts, openings, warnings, and scan confidence. Field names and storage formats may change once the Xcode project and persistence choice are finalized. The conceptual model should remain stable enough to support scanning, correction, editing, validation, and local save/reload.

## Cross-cutting fields

Most persisted entities should include:

| Field | Purpose |
| --- | --- |
| `id` | Stable identifier within the local dataset |
| `createdAt` | Creation timestamp |
| `updatedAt` | Last modification timestamp |
| `schemaVersion` | Version used for migration and compatibility checks |

Identifiers must remain stable across relaunch. Rescan reconciliation should prefer preserving existing IDs when an object can be matched confidently.

## Room

A room is the root local document for the MVP.

| Field | Description |
| --- | --- |
| `id` | Room identifier |
| `name` | User-visible room name |
| `createdAt` | Creation date |
| `lastScanAt` | Last successful scan date |
| `schemaVersion` | Persistence schema version |
| `walls` | Wall segments that define the room boundary |
| `doors` | Door openings |
| `windows` | Window openings |
| `openings` | Other openings that affect circulation or placement |
| `objects` | Detected or manually added objects |
| `originalArrangement` | Snapshot of object poses from the trusted baseline |
| `savedLayouts` | Named alternate layouts for the room |
| `scanConfidence` | Overall confidence summary for the latest scan |
| `notes` | Optional user notes |

### Walls

| Field | Description |
| --- | --- |
| `id` | Wall identifier |
| `start` | Start point in room coordinates |
| `end` | End point in room coordinates |
| `height` | Wall height when known |
| `thickness` | Optional thickness |
| `confidence` | Detection confidence |

### Openings

Doors, windows, and generic openings share a common shape with a type discriminator.

| Field | Description |
| --- | --- |
| `id` | Opening identifier |
| `type` | `door`, `window`, or `opening` |
| `position` | Position in room coordinates |
| `width` | Opening width |
| `height` | Opening height when known |
| `rotation` | Orientation in the room plane |
| `wallId` | Optional associated wall |
| `clearance` | Optional required or preferred clearance |
| `confidence` | Detection confidence |

## Object

Objects are the editable contents of a room.

| Field | Description |
| --- | --- |
| `id` | Object identifier |
| `name` | User-visible name |
| `category` | Category such as sofa, table, bed, chair, storage, other |
| `dimensions` | Width, depth, and height |
| `position` | Position in room coordinates |
| `rotation` | Rotation around the vertical axis for top-down editing |
| `movableState` | `movable`, `fixed`, or `excluded` |
| `confidence` | Detection confidence |
| `detectionSource` | `roomPlan`, `manual`, or later sources as needed |
| `referenceImage` | Optional local reference image metadata |
| `isUserCorrected` | Whether the user has manually corrected this object |
| `removed` | Soft-removal marker for false detections when useful for history |

### Dimensions

| Field | Description |
| --- | --- |
| `width` | X extent |
| `depth` | Y extent in the floor plane |
| `height` | Z extent |

Units should be consistent across the app. Meters are preferred for internal storage; presentation can convert to locale-friendly units.

### Movable state

| Value | Meaning |
| --- | --- |
| `movable` | May be dragged and rotated in the layout editor |
| `fixed` | Must not move unless the user changes state |
| `excluded` | Ignored by editing and suggestions |

## Arrangement and layouts

### Original arrangement

The original arrangement is the trusted baseline for restore-original behavior. It stores object poses and membership as of the baseline scan or the last user-accepted reconciliation.

| Field | Description |
| --- | --- |
| `capturedAt` | When the baseline was established |
| `objectPoses` | Map or list of object IDs with position and rotation |
| `sourceScanId` | Optional scan session reference |

### Saved layout

| Field | Description |
| --- | --- |
| `id` | Layout identifier |
| `name` | User-visible layout name |
| `createdAt` | Creation date |
| `updatedAt` | Last edit date |
| `objectPoses` | Object IDs with position and rotation |
| `warningsSnapshot` | Optional warnings present when saved |
| `notes` | Optional explanation or user note |

Restore-original must not delete saved layouts. Applying a suggestion should create or update an editable layout rather than silently overwriting unrelated saves.

## Warnings

Validation produces warnings rather than silently blocking every edit.

| Field | Description |
| --- | --- |
| `id` | Warning identifier |
| `type` | `overlap`, `wallBoundary`, `doorway`, `walkway`, or similar |
| `severity` | `info`, `warning`, or `error` |
| `objectIds` | Related objects |
| `openingIds` | Related openings when applicable |
| `message` | User-visible explanation |
| `isOverridable` | Whether the user may proceed despite the warning |

## Scan confidence

Confidence helps the correction UI prioritize uncertain detections.

| Field | Description |
| --- | --- |
| `overall` | Room-level confidence summary |
| `objectConfidences` | Per-object values |
| `structureConfidence` | Confidence in walls and openings |
| `incompleteAreas` | Optional regions that may need rescanning |

## Persistence expectations

- Local-only for MVP
- Schema version required on persisted room documents
- Corrupt or incompatible files must fail safely
- Deleting a room deletes its objects, layouts, and related local artifacts
- Reference images, if used, remain on device and are deleted with the room

## Non-goals for the initial model

- Cloud document sync
- Multi-room graph relationships
- Vendor product SKUs as first-class objects
- Photoreal material or mesh authoring data
- Account-owned collaborative locks or permissions
