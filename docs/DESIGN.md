# Freeshots design plan

## Archetype

Menu bar extra with capture overlays, a floating screenshot editor, and a Settings window. There is no persistent screenshot library or sidebar.

## Information architecture

- **Menu bar:** Capture Area, Capture Window, Capture Display, Settings, Quit.
- **Capture overlay:** choose or confirm the screen content to capture; Escape cancels.
- **Floating Editor:** review one screenshot, add markup, then Copy, Save, or Drag to Save.
- **Settings:** Keyboard Shortcuts and Appearance.

## Command map

| Action | Entry point | Shortcut |
|---|---|---|
| Capture Area | Menu bar and app menu | User-configurable |
| Capture Window | Menu bar and app menu | User-configurable |
| Capture Display | Menu bar and app menu | User-configurable |
| Copy screenshot | Floating Editor, Edit menu | Command-C |
| Save screenshot | Floating Editor, File menu | Command-S |
| Undo / Redo markup | Floating Editor, Edit menu | Command-Z / Shift-Command-Z |
| Close editor | Floating Editor, Window menu | Command-W |
| Settings | Menu bar/app menu | Command-comma |
| Quit | Menu bar/app menu | Command-Q |

Markup tool shortcuts will be listed in the editor and configured in Settings. Defaults are a design call for the next pass.

## Empty states

- Capture is initiated from the menu bar; no empty editor opens at launch.
- If the editor is opened without a screenshot during development, show “No Screenshot” with the first action: “Choose a capture mode from the menu bar.”
- Permission errors appear in the capture overlay with a direct explanation and the macOS Settings action needed to continue.

## Feeling

Instant and focused. The screenshot stays central; capture controls and markup tools appear only when useful. The app gets a custom visual identity while keeping familiar Mac shortcuts, menus, save panels, and drag-and-drop behavior.
