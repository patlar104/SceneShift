# Issue 2: Add hardware and permission checks

## Summary

Detect unsupported devices and missing permissions before scanning begins, and recover gracefully when access is denied.

## Acceptance criteria

- [ ] Camera permission handled
- [ ] Unsupported-device state displayed
- [ ] RoomPlan support checked at runtime
- [ ] Permission denial does not crash the app
- [ ] User receives recovery instructions

## Notes

Keep messaging actionable and privacy-aware. Request camera access only when needed for scanning.
