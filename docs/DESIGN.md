# Freeshots design plan

## Archetype

Menu bar extra with capture overlays, a floating screenshot editor, and a Settings window. There is no persistent screenshot library or navigation sidebar; the editor uses an inspector alongside its canvas.

## Information architecture

- **Menu bar:** Capture Area, Capture Window, Capture Display, Show Last Screenshot when available, Settings, Quit.
- **Capture overlay:** choose or confirm the screen content to capture; Escape cancels.
- **Floating Editor:** screenshot canvas with a persistent right inspector for markup and backdrop controls; Copy, Save, and Drag to Save are grouped at the top of the Inspector.
- **Settings:** Keyboard Shortcuts, Editor preferences, and Privacy.

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

The editor uses a persistent Finder-style right side panel with a native material surface and no panel title. Its top action row groups Copy, Save, icon-only Undo/Redo, and Drag to Save. Markup tools and appearance settings follow. Native window controls retain AppKit placement. The screenshot canvas expands beside the inspector and previews changes immediately. Copy, Save, and Drag to Save share the same appearance model and sit together at the top of the Inspector.

Markup tool shortcuts appear in the Inspector tooltips and work throughout the editor.

## Empty states

- Capture is initiated from the menu bar; no empty editor opens at launch.
- If the editor is opened without a screenshot during development, show “No Screenshot” with the first action: “Choose a capture mode from the menu bar.”
- Permission errors appear in the capture overlay with a direct explanation and the macOS Settings action needed to continue.

## Feeling

Instant and focused. The screenshot stays central; its tools stay close in the inspector. The app gets a custom visual identity while keeping familiar Mac shortcuts, menus, save panels, and drag-and-drop behavior.
