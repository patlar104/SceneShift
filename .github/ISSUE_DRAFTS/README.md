# Create these GitHub issues

The cloud agent token for this repository cannot create issues (`Resource not accessible by integration`). Use the drafts in this folder to create them with a account that has Issues write access.

Suggested command pattern:

```bash
gh issue create --title "Create the SceneShift Xcode project" --body-file .github/ISSUE_DRAFTS/01-create-xcode-project.md
gh issue create --title "Add hardware and permission checks" --body-file .github/ISSUE_DRAFTS/02-hardware-permission-checks.md
gh issue create --title "Implement basic RoomPlan scanning" --body-file .github/ISSUE_DRAFTS/03-basic-roomplan-scanning.md
gh issue create --title "Define room and object models" --body-file .github/ISSUE_DRAFTS/04-room-object-models.md
gh issue create --title "Save and reload one room locally" --body-file .github/ISSUE_DRAFTS/05-save-reload-room.md
gh issue create --title "Build the top-down layout editor" --body-file .github/ISSUE_DRAFTS/06-top-down-layout-editor.md
gh issue create --title "Add manual correction controls" --body-file .github/ISSUE_DRAFTS/07-manual-correction-controls.md
gh issue create --title "Add undo, redo, and restore-original behavior" --body-file .github/ISSUE_DRAFTS/08-undo-redo-restore.md
gh issue create --title "Add placement validation" --body-file .github/ISSUE_DRAFTS/09-placement-validation.md
gh issue create --title "Add first layout-suggestion prototype" --body-file .github/ISSUE_DRAFTS/10-layout-suggestion-prototype.md
```

Create them in order so numbering and roadmap sequencing stay aligned.
