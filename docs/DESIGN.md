# Freeshots design plan

## Archetype

Menu bar extra with capture overlays, a floating screenshot editor, and a Settings window. There is no persistent screenshot library or navigation sidebar; the editor uses a compact toolbar with visual Background and Aspect Ratio popovers, a Device Frame menu, and a Fine Tune popover.

## Information architecture

- **Menu bar:** Open Image, Capture Area, Capture Window, Capture Display, Show Last Screenshot when available, Settings, Quit.
- **Capture overlay:** choose or confirm the screen content to capture; Escape cancels.
- **Floating Editor:** full-width screenshot canvas beneath a compact toolbar. Markup, history, and color lead; Background, Aspect Ratio, Device Frame, and Fine Tune follow Undo/Redo behind a separator; Copy, Save, and drag stay at the trailing end. Background and Aspect Ratio open visual previews, and Fine Tune opens an anchored popover.
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

The editor uses a compact top toolbar above a full-width screenshot canvas. It groups markup tools, color, and Undo/Redo, then icon-only styling actions with visual popovers for Background and Aspect Ratio, a Device Frame menu, and Fine Tune controls. Fine Tune settings appear in a native popover only while needed. The image remains the visual center without a permanent side panel. Copy, Save, and Drag to Save use the same renderer as the editor composition.

Markup tool shortcuts appear in toolbar tooltips and work throughout the editor.

## Empty states

- Capture is initiated from the menu bar; no empty editor opens at launch.
- If the editor is opened without a screenshot during development, show “No Screenshot” with the first action: “Choose a capture mode from the menu bar.”
- Permission errors appear in the capture overlay with a direct explanation and the macOS Settings action needed to continue.

## Feeling

Instant and focused. The screenshot stays central; frequent tools sit in one predictable toolbar, while occasional styling controls stay one click away. The app keeps familiar Mac shortcuts, menus, save panels, and drag-and-drop behavior.
