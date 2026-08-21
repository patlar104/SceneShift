# SceneShift Privacy

SceneShift is privacy-first. The MVP treats room geometry, object inventories, and layout plans as sensitive personal data about a user’s home.

## MVP privacy requirements

The first version will:

- Store room data locally on the device
- Require no account
- Upload nothing by default
- Allow individual room deletion
- Allow full local data deletion
- Avoid retaining unnecessary camera frames
- Keep sensitive room geometry out of diagnostic logs

## Local-only default

All scan results, corrections, layouts, warnings, and optional reference images remain on device unless a future version introduces an explicit, user-controlled sharing path. The MVP must not depend on cloud sync, analytics backends that receive room contents, or account systems.

## Permissions

- Request camera access only when needed for scanning
- Explain why camera access is required before or during the system prompt
- Handle permission denial without crashing
- Provide recovery instructions when permission is denied
- Check RoomPlan and device support before offering capture

## Data minimization

- Prefer structured room and object models over raw video retention
- Do not keep camera frames longer than needed to produce the scan result
- Do not include wall, door, window, or object geometry in routine logs
- Prefer coarse error codes and non-sensitive diagnostics in logs
- Avoid screenshots or exports that leave the device unless the user explicitly initiates sharing in a future feature

## Deletion controls

Users must be able to:

1. Delete a single room and all related local data for that room
2. Delete all SceneShift local data from the app

Room deletion should remove:

- Room metadata
- Objects and layouts
- Opening and wall data
- Optional reference images
- Any derived cache tied to that room

## Rescanning

When a room is rescanned, previous local data may be reconciled or replaced according to product rules, but discarded scan intermediates should not linger. Manual corrections should be preserved when reconciliation can do so safely.

## Future sharing

If later versions add shared projects, cloud backup, or Vision Pro continuity, those features must be:

- Opt-in
- Clearly labeled
- Limited to the data the user chooses to share
- Removable by the user

Do not introduce cloud dependencies into the MVP.

## Review checklist for contributors

Before merging a change, confirm:

- No default network upload of room contents
- No account requirement added for core flows
- No sensitive geometry written to logs
- Deletion paths still work for rooms and full local data
- New persistence remains on device
