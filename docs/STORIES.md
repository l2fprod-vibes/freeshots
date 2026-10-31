# Freeshots stories

## M1 — Screenshot core loop

The user can capture a screenshot, mark it up, and copy, save, or drag it to a local destination. Screens listed here are target snapshot names; no reference screenshots exist yet.

### S-001 Choose a capture mode from the menu bar

As the user, I open the menu bar item and choose Capture Area, Capture Window, or Capture Display.

Screens: 01-menu-bar.png, 02-area-selection.png, 03-window-selection.png

Acceptance:
- [manual] The menu bar item is available while Freeshots is running without opening a main window.
- [manual] Each capture command starts the matching capture flow.
- [manual] Escape cancels capture and returns to the desktop without opening the editor.
- [snap] The menu uses the labels Capture Area, Capture Window, Capture Display, Settings, and Quit.

UX:
- Flow: menu bar item -> Capture Area/Window/Display -> matching capture flow -> Escape cancels or capture opens the Floating Editor.
- Surface: menu bar menu, a few related actions tied to one control.
- States: menu offers the three capture modes, Settings, and Quit; capture starts immediately after a mode is chosen.
- Words: "Capture Area", "Capture Window", "Capture Display", "Settings", "Quit".
- Access: menu actions are keyboard navigable; VoiceOver announces each menu item by the same name.

Status: done

### S-002 Start a capture with a keyboard shortcut

As the user, I press a configured shortcut to start an area, window, or display capture without opening the menu.

Screens: 04-shortcut-settings.png

Depends: S-001

Acceptance:
- [manual] Settings let me assign a separate shortcut to each capture mode.
- [manual] Pressing an assigned shortcut starts its matching capture flow from another app.
- [manual] A shortcut already used by another Freeshots action cannot be assigned twice; the conflict is explained beside the shortcut field.
- [manual] I can restore the original shortcuts.

UX:
- Flow: menu bar item -> Settings -> Keyboard Shortcuts -> record a shortcut -> close Settings; press the shortcut anywhere -> capture flow.
- Surface: Settings window, a self-contained place to configure shortcuts.
- States: each shortcut shows its current keys; conflicts appear inline with a clear fix; Restore Defaults returns the shipped shortcut set.
- Words: "Keyboard Shortcuts", "Restore Defaults", "Shortcut already in use".
- Access: shortcut fields work by keyboard and VoiceOver; Escape cancels shortcut recording.

Status: done

### S-003 Capture a display, window, or area

As the user, I capture the exact screen content I need and continue directly to the Floating Editor.

Screens: 02-area-selection.png, 03-window-selection.png, 05-display-capture.png

Depends: S-001

Acceptance:
- [manual] Display capture records the selected display at its native pixel dimensions.
- [manual] Window capture lets me point to a visible window and select it.
- [manual] Area capture lets me drag a rectangle and adjust its edges before confirming.
- [manual] Escape cancels selection; Return confirms an area selection.
- [manual] The captured screenshot opens in the Floating Editor without an intermediate save dialog.
- [manual] Capture works on each connected display, including mixed-resolution displays.

UX:
- Flow: menu command or shortcut -> select display/window/area -> Return or click confirms -> Floating Editor; Escape cancels.
- Surface: lightweight capture overlay; selection happens over the screen being captured.
- States: area selection shows its bounds and dimensions; window selection highlights the target; capture errors explain how to grant Screen Recording access in System Settings.
- Words: "Select an area", "Select a window", "Select a display", "Capture".
- Access: keyboard can move and resize an area selection; VoiceOver announces selection bounds and confirmation/cancel actions; selection is not communicated by color alone.

Status: done

### S-004 Review a screenshot in the Floating Editor

As the user, I see the screenshot immediately after capture so I can decide what to do next.

Screens: 06-floating-editor.png

Depends: S-003

Acceptance:
- [snap] The full screenshot is visible at a useful fit-to-window scale.
- [snap] The title bar shows Copy and Save icons followed by markup tools; a discreet drag icon sits at the bottom.
- [manual] Without Screen Recording Permission, the editor shows a blank screenshot and keeps all toolbar icons visible; markup tools remain usable, while Copy, Save, and drag are disabled.
- [manual] A permission message and an Open Settings action appear at the bottom of the editor.
- [manual] Open Settings hides the floating editor so System Settings is visible.
- [manual] Closing the editor discards an unsaved capture after a clear prompt only if edits would otherwise be lost; Escape closes an untouched capture.
- [manual] Reopening the editor is not required to copy or save a capture.

UX:
- Flow: capture completes -> Floating Editor shows the image -> choose Copy, Save, a markup tool, drag the bottom handle, or close.
- Surface: floating panel kept beside the work, because the user needs to inspect the screenshot and act on it.
- States: capture appears immediately; without Screen Recording Permission, a blank screenshot remains available for markup testing and the permission message appears at the bottom with an Open Settings action that hides the floating editor.
- Words: no capture-mode title; title bar actions "Copy", "Save…", followed by markup tools; bottom drag handle has no visible label; bottom status "Screen Recording permission required" and action "Open Settings".
- Access: title bar actions have keyboard shortcuts, tooltips, and VoiceOver labels; Escape closes when no edit is in progress; window can be moved without blocking the screenshot.

Status: done

### S-005 Mark up a screenshot

As the user, I add and adjust arrows, shapes, text, pen strokes, or redactions on the screenshot.

Screens: 07-markup.png

Depends: S-004

Acceptance:
- [manual] I can add, select, move, and remove arrow, shape, text, pen, and redaction marks.
- [manual] Markup stays editable in the Floating Editor until I close or export the screenshot.
- [manual] Undo and Redo restore the previous markup state.
- [manual] Redacted pixels are permanently covered in copied, saved, and dragged output; the original pixels cannot be recovered from the exported image.
- [snap] Each icon-only markup tool has a tooltip that names the action and its shortcut.

UX:
- Flow: choose Arrow/Shape/Text/Pen/Redact -> place or draw mark -> select to adjust -> Undo/Redo or continue to Copy/Save/drag.
- Surface: tools in the Floating Editor toolbar; selecting a tool changes how the next canvas gesture behaves.
- States: selected marks show handles; empty text edits can be canceled with Escape; redaction uses a solid opaque fill and is identified by a label as well as color.
- Words: "Arrow", "Shape", "Text", "Pen", "Redact", "Undo", "Redo".
- Access: every tool has a keyboard shortcut, VoiceOver name, and visible focus state; Escape exits text editing or the active tool before closing the editor.

Status: done

### S-006 Copy a screenshot to the clipboard

As the user, I copy the current screenshot to the clipboard and paste it into another app.

Screens: 06-floating-editor.png

Depends: S-004

Acceptance:
- [manual] Copy places the full-resolution PNG, including current markup, on the clipboard.
- [manual] Copy leaves the Floating Editor open so I can continue editing or save the same capture.
- [snap] A brief "Copied" confirmation appears in the editor after copying.
- [manual] Copy works without an internet connection and makes no network request.

UX:
- Flow: select Copy or press its shortcut -> PNG is placed on the clipboard -> "Copied" appears -> editor remains open.
- Surface: toolbar action in the Floating Editor.
- States: success is confirmed inline; clipboard failure leaves the editor open and explains the retry action.
- Words: "Copy", "Copied", "Unable to copy screenshot. Try again.".
- Access: Copy has a keyboard shortcut, VoiceOver label, and tooltip; confirmation is also announced to VoiceOver.

Status: done

### S-007 Save a screenshot as a file

As the user, I save the current screenshot and its markup as a PNG file on my Mac.

Screens: 06-floating-editor.png, 08-save-panel.png

Depends: S-004

Acceptance:
- [manual] Save opens the macOS save panel with a timestamped filename and PNG format selected.
- [manual] The save panel appears as a sheet in front of the Floating Editor.
- [manual] Saving writes the visible screenshot and markup to the chosen local folder.
- [manual] Cancel returns to the editor without losing the capture or edits.
- [manual] Save works offline and makes no network request.

UX:
- Flow: choose Save… -> macOS save panel opens with filename selected -> Save writes the file and returns to the Floating Editor; Cancel returns without saving.
- Surface: macOS save panel, a short task that needs a location and filename.
- States: filename is prefilled; write failures appear inline with a retry; cancellation keeps the editor unchanged.
- Words: "Save…", "Save", "Cancel", "Unable to save screenshot. Choose another location or try again.".
- Access: the save panel follows standard macOS keyboard behavior; VoiceOver announces the filename, destination, and error.

Status: done

### S-008 Drag a screenshot to the Desktop or a folder

As the user, I drag the icon-only handle at the bottom of the Floating Editor to the Desktop or a folder to create a PNG there.

Screens: 06-floating-editor.png

Depends: S-004

Acceptance:
- [manual] Dragging the labeled file handle to the Desktop or a Finder folder creates a PNG with the current markup.
- [manual] The suggested filename is timestamped and receives a unique suffix if that name already exists at the destination.
- [manual] Canceling a drag leaves the Floating Editor and screenshot unchanged.
- [snap] The drag handle has a visible label and a tooltip explaining that it creates a file.

UX:
- Flow: drag bottom handle -> hover over Desktop/folder -> release to create PNG; cancel by returning to the editor.
- Surface: drag handle in the Floating Editor, the lightest interaction for creating a file in a chosen destination.
- States: handle shows a ready cursor while dragging over a valid destination; cancel returns to the editor with no change.
- Words: no visible label; tooltip "Drag this screenshot to create a PNG file".
- Access: the same screenshot can also be saved with the Save… action; VoiceOver identifies the handle as "Drag to Save" and explains that it creates a PNG file.

Status: done

## Later

- **V2:** Record a display, window, or area as a local video; preview and save or drag the clip. Audio, camera, and video editing scope remain undecided.

## Dropped

- Cloud uploads, share links, accounts, sync, analytics, and telemetry.
- Screenshot history/library, search, OCR, scrolling capture, and multi-image composition.
