# SceneShift Vision

SceneShift is an intelligent spatial-planning app that scans real-world environments, understands objects and usable space, and helps users test changes before moving anything physically.

The product goal is to make layout decisions safer, faster, and more confident. Users should be able to capture a room, correct what the scan got wrong, try alternative arrangements digitally, and only then rearrange furniture in the physical world.

## Product principle

SceneShift starts from the room as it exists today. It does not assume empty floor plans or idealized catalogs. Capture, correction, editing, validation, and suggestion all build on a privacy-first local model of one room and the objects inside it.

## Near-term focus

The first versions concentrate on a single room:

- Capture with Apple RoomPlan and ARKit
- Convert scan results into editable room and object models
- Let users correct detection mistakes
- Edit layouts from a clear top-down view
- Warn about collisions, doorway blockage, and poor walkways
- Save and restore arrangements locally

## Future directions

Once the one-room loop is reliable, SceneShift can expand into:

### Accessibility analysis

Evaluate clearances, reach ranges, turning space, and pathway continuity for accessibility-conscious layout decisions.

### Storage optimization

Identify underused volume, suggest denser but still usable storage arrangements, and highlight clutter that blocks circulation.

### Multi-room planning

Connect rooms into a shared project so users can plan flow across adjacent spaces, not just within one room.

### Moving and renovation support

Help users plan packing order, temporary staging layouts, construction clearances, and post-move furniture placement.

### Apple Vision Pro support

Bring immersive spatial review to visionOS so users can evaluate proposed layouts at life size.

### Natural-language layout requests

Allow requests such as “make a reading corner by the window” or “keep a clear path to the door,” then translate them into ranked layout suggestions.

### Shared projects

Support collaborative planning for households, designers, and movers while preserving explicit consent and clear privacy boundaries around room geometry.

## Success criteria

SceneShift succeeds when a user can scan a real room, fix the model quickly, try meaningful layout options, understand the tradeoffs, and leave with a plan they trust—without uploading their home by default.
