# Issue 8: Add undo, redo, and restore-original behavior

## Summary

Make layout experimentation safe by supporting undo, redo, and restore-original without destroying saved layouts.

## Acceptance criteria

- [ ] Move operations can be undone
- [ ] Rotation operations can be undone
- [ ] Redo works
- [ ] Original scan can be restored
- [ ] Saved layouts are not destroyed accidentally

## Notes

Restore-original should return to the trusted baseline arrangement without deleting alternate saved layouts.
