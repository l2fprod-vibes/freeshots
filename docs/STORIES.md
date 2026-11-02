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
- Flow: menu bar item or Command-comma -> Settings -> choose General, Keyboard Shortcuts, or Permissions -> adjust a value or record a shortcut -> close Settings; press a configured shortcut anywhere -> capture flow.
- Surface: native Settings window with topic tabs, the lightest standard navigation for a small set of related preference groups.
- States: the selected tab is remembered; each shortcut shows its current keys; conflicts appear inline with a clear fix; Restore Defaults returns the shipped shortcut set; Permissions shows the current Screen Recording state.
- Words: "Keyboard Shortcuts", "Restore Defaults", "Shortcut already in use".
- Access: tabs and shortcut fields work by keyboard and VoiceOver; Escape cancels shortcut recording.

Status: done

### S-003 Capture a display, window, or area

As the user, I capture the exact screen content I need and continue directly to the Floating Editor.

Screens: 02-area-selection.png, 03-window-selection.png, 05-display-capture.png

Depends: S-001

Acceptance:
- [manual] Display capture records the selected display at its native pixel dimensions.
- [manual] Window capture lets me point to a visible window and select it.
- [manual] Settings includes Include Window Shadow, off by default; when enabled, window captures include the macOS shadow, and when disabled they omit it.
- [manual] Area capture lets me drag a rectangle and adjust its edges before confirming.
- [manual] Escape cancels selection; Return confirms an area selection.
- [manual] The captured screenshot opens in the Floating Editor without an intermediate save dialog.
- [manual] Capture works on each connected display, including mixed-resolution displays.

UX:
- Flow: Settings -> Capture -> Include Window Shadow toggle sets the window capture appearance; menu command or shortcut -> select display/window/area -> Return or click confirms -> Floating Editor; Escape cancels.
- Surface: lightweight capture overlay for selection, plus the Include Window Shadow toggle in Settings.
- States: Include Window Shadow is off by default; area selection shows its bounds and dimensions; window selection highlights the target; capture errors explain how to grant Screen Recording access in System Settings.
- Words: "Select an area", "Select a window", "Select a display", "Capture", "Include Window Shadow".
- Access: keyboard can move and resize an area selection; VoiceOver announces selection bounds and confirmation/cancel actions; Include Window Shadow is keyboard accessible; selection is not communicated by color alone.

Status: done

### S-004 Review a screenshot in the Floating Editor

As the user, I see the screenshot immediately after capture so I can decide what to do next.

Screens: 06-floating-editor.png

Depends: S-003

Acceptance:
- [snap] The full screenshot is visible at a useful fit-to-window scale.
- [snap] A compact toolbar spans the editor above the canvas. Markup tools and Undo/Redo are grouped on the leading side; Background, Aspect Ratio, Device Frame, Fine Tune, Copy, Save, and Drag to Save are on the trailing side.
- [manual] Without Screen Recording Permission, the editor shows a blank screenshot and keeps toolbar controls visible; markup tools remain usable, while Copy, Save, and Drag to Save are disabled.
- [manual] A permission message and an Open Settings action appear at the bottom of the editor.
- [manual] Open Settings hides the floating editor so System Settings is visible.
- [manual] Closing the editor discards an unsaved capture after a clear prompt only if edits would otherwise be lost; Escape closes an untouched capture.
- [manual] Reopening the editor is not required to copy or save a capture.

UX:
- Flow: capture completes -> Floating Editor shows the image -> choose a markup tool, use the styling menus or Fine Tune, Copy, Save, drag to save, or close.
- Surface: floating panel kept beside the work, because the user needs to inspect the screenshot and act on it.
- States: capture appears immediately; without Screen Recording Permission, a blank screenshot remains available for markup testing and the permission message appears at the bottom with an Open Settings action that hides the floating editor.
- Words: no capture-mode title; Background, Aspect Ratio, Device Frame, Fine Tune, Copy, Save, and Drag to Save are in the editor toolbar; bottom status "Screen Recording permission required" and action "Open Settings".
- Access: toolbar actions have keyboard shortcuts, tooltips, and VoiceOver labels; Escape closes when no edit is in progress; window can be moved without blocking the screenshot.

Status: done

### S-005 Mark up a screenshot

As the user, I add and adjust arrows, shapes, text, pen strokes, or redactions on the screenshot.

Screens: 07-markup.png

Depends: S-004

Acceptance:
- [manual] I can add, select, move, and remove arrow, shape, text, pen, redaction, and blur marks.
- [manual] The Arrow toolbar action opens a popup with Solid, Open, Dashed, and Double styles; the selected style applies to new arrows and existing arrows keep their saved style.
- [manual] Markup stays editable in the Floating Editor until I close or export the screenshot.
- [manual] Undo and Redo restore the previous markup state.
- [manual] Redacted pixels are permanently covered in copied, saved, and dragged output; the original pixels cannot be recovered from the exported image.
- [snap] Each icon-only markup tool has a tooltip that names the action and its shortcut.

UX:
- Flow: choose Arrow/Shape/Text/Pen/Redact/Blur -> place or draw mark -> select to adjust -> Undo/Redo or continue to Copy/Save/drag.
- Surface: tools in the Floating Editor toolbar; selecting a tool changes how the next canvas gesture behaves.
- States: selected marks show handles; empty text edits can be canceled with Escape; redaction uses a solid opaque fill and is identified by a label as well as color.
- Words: "Arrow", "Shape", "Text", "Pen", "Redact", "Blur", "Undo", "Redo".
- Flow: choose an Arrow Style from the Arrow toolbar popup -> draw an arrow -> the selected style remains active for the next arrow.
- Surface: popup menu attached to Arrow, a few related choices tied to one toolbar action.
- States: Solid is the default; the current style is checked in the popup and exposed as Arrow's accessibility value.
- Words: "Solid", "Open", "Dashed", "Double", "Arrow Style".
- Access: every tool has a keyboard shortcut, VoiceOver name, and visible focus state; Escape exits text editing or the active tool before closing the editor.

Status: done

### S-006 Copy a screenshot to the clipboard

As the user, I copy the current screenshot to the clipboard and paste it into another app.

Screens: 06-floating-editor.png

Depends: S-004

Acceptance:
- [manual] Copy places the full-resolution PNG, including current markup, on the clipboard.
- [manual] Copy leaves the Floating Editor open so I can continue editing or save the same capture.
- [manual] Copy completes without displaying a success label; failures remain visible in the editor.
- [manual] Copy uses the same rendered composition as the editor preview, including the selected device frame and its details.
- [manual] Copy works without an internet connection and makes no network request.

UX:
- Flow: select Copy or press its shortcut -> PNG is placed on the clipboard -> editor remains open.
- Surface: icon action in the editor toolbar.
- States: success is quiet; clipboard failure leaves the editor open and explains the retry action.
- Words: "Copy", "Unable to copy screenshot. Try again.".
- Access: Copy has a keyboard shortcut, VoiceOver label, and tooltip.

Status: done

### S-007 Save a screenshot as a file

As the user, I save the current screenshot and its markup as a PNG file on my Mac.

Screens: 06-floating-editor.png, 08-save-panel.png

Depends: S-004

Acceptance:
- [manual] Save opens the macOS save panel with a timestamped filename and PNG format selected.
- [manual] The save panel appears as a sheet in front of the Floating Editor.
- [manual] Saving writes the visible screenshot and markup to the chosen local folder.
- [manual] The saved composition matches the editor preview, including window controls and device frame details.
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

As the user, I drag the labeled handle in the Floating Editor toolbar to the Desktop or a folder to create a PNG there.

Screens: 06-floating-editor.png

Depends: S-004

Acceptance:
- [manual] Dragging the toolbar handle to the Desktop or a Finder folder creates a PNG with the current markup.
- [manual] The dragged composition matches the editor preview, including window controls and device frame details.
- [manual] The suggested filename is timestamped and receives a unique suffix if that name already exists at the destination.
- [manual] Canceling a drag leaves the Floating Editor and screenshot unchanged.
- [snap] The handle shows “Drag to Save” beside a six-dot grip, making its draggable area clear.
- [snap] The drag handle has a tooltip explaining that it creates a file.

UX:
- Flow: drag the toolbar handle -> hover over Desktop/folder -> release to create PNG; cancel by returning to the editor.
- Surface: drag handle in the editor toolbar, the lightest interaction for creating a file in a chosen destination.
- States: handle shows a ready cursor while dragging over a valid destination; cancel returns to the editor with no change.
- Words: visible label and accessibility label "Drag to Save"; tooltip "Drag this screenshot to create a PNG file".
- Access: the same screenshot can also be saved with the Save… action; VoiceOver identifies the handle as "Drag to Save" and explains that it creates a PNG file.

Status: done

### S-009 Style screenshots and markups

As the user, I choose a markup color and style the screenshot against a configurable backdrop before copying, saving, or dragging it.

Acceptance:
- Markup color can be changed from a circular control in the toolbar; new marks default to red.
- Blur is a rectangular markup tool that obscures the selected screenshot area in the preview and exported image.
- The color control offers common swatches first and a custom macOS color picker.
- Background and Aspect Ratio open toolbar popovers with visual previews; Device Frame remains a toolbar menu and Fine Tune opens a toolbar popover. Styling controls follow Undo/Redo behind a separator; Copy, Save, and Drag to Save remain at the trailing end.
- Backdrop presets preview solid, gradient, and textured backgrounds as I choose them, including Coral, Lagoon, Lavender, Amber, Moss, Sand, Graphite Grid, and Rose Dots.
- Padding, screenshot corner radius, overall picture corner radius, shadow blur, and shadow opacity have adjustable values.
- Reset Appearance is a toolbar action immediately after Fine Tune. It sets Background to None, Aspect Ratio to Original, Device Frame to None, sets padding and both corner radii to zero, and disables Shadow with blur and opacity set to zero.
- The Fine Tune popover does not contain a Reset Appearance button.
- The default picture uses a textured linen backdrop and tighter padding.
- Aspect Ratio offers Original, 1:1, 4:3, and 16:9; the canvas adds space around the unchanged screenshot to match the selected ratio, and portrait images stay portrait.
- Optional Window, Mac, and phone frames are mutually exclusive. Window adds a standard macOS title bar with traffic lights.
- The Window frame uses the screenshot’s dominant sampled color.
- With the Window frame selected, the screenshot remains clipped inside its rounded lower corners even when Screenshot Corners is set to zero.
- Copy, Save, drag, and the editor preview use the same appearance settings.

UX:
- Flow: choose a markup tool and color in the toolbar -> open Background or Aspect Ratio to preview and choose, select Device Frame, adjust Fine Tune, or choose Reset Appearance -> Copy, Save, or drag.
- Surface: icon-only styling controls after Undo/Redo; Background and Aspect Ratio use preview popovers, Device Frame uses a menu, Fine Tune uses a popover for sliders, and Reset Appearance is a toolbar action immediately after Fine Tune.
- States: default is a linen backdrop with adjustable padding and shadow; Reset Appearance clears the backdrop, frame, padding, corner radii, and shadow, and restores the original aspect ratio; preview updates while settings change.
- Words: “Markup Color”, “Custom Color”, “Background”, “Padding”, “Screenshot Corners”, “Picture Corners”, “Shadow”, “Shadow Blur”, “Shadow Opacity”, “Aspect Ratio”, “Original”, “1:1”, “4:3”, “16:9”, “Device Frame”, “Fine Tune”, “Reset Appearance”.
- Access: color swatches and all backdrop controls are keyboard accessible and VoiceOver labeled.

### S-011 Open a local image

As the user, I open an image from the menu bar and edit it in the Floating Editor.

Acceptance:
- [manual] Open Image… presents the macOS image picker and loads the selected image into the editor.
- [manual] The selected image supports the same markup, appearance, copy, save, and drag actions as a capture.
- [manual] Canceling the picker leaves the current editor unchanged; image data remains local.

UX:
- Flow: choose Open Image… or press Command-O -> select an image -> edit it in the Floating Editor.
- Surface: menu bar extra and standard macOS open panel.
- States: unsupported or unreadable images leave the current editor unchanged.
- Words: “Open Image…”, “Open”, “Cancel”.
- Access: the open panel follows standard macOS keyboard and VoiceOver behavior.

### S-010 Reopen the last screenshot

As the user, I can choose whether Freeshots remembers the latest capture and reopen it from the menu bar.

Acceptance:
- Remember Last Screenshot is enabled by default and can be turned off in Settings.
- The last capture is stored only on this Mac.
- Show Last Screenshot appears in the menu bar menu when a remembered capture exists.
- Choosing it opens the Floating Editor with the remembered image.

UX:
- Flow: enable Remember Last Screenshot in Settings -> capture -> menu bar item -> Show Last Screenshot -> editor opens.
- Surface: Settings toggle and menu bar command (toggle is one preference; command is an entry point).
- States: command is absent when no screenshot is stored or remembering is disabled.
- Words: “Remember Last Screenshot”, “Show Last Screenshot”.
- Access: both controls are keyboard navigable and VoiceOver labeled.

### S-012 Name screenshots and show the name in the Floating Editor

As the user, I get a useful default name for each screenshot and can see the screenshot or open image name in the Floating Editor title bar.

Acceptance:
- [manual] Area and display captures use an Apple-style timestamped default name.
- [manual] Window capture uses the selected window's title when available, which can be a document name or browser tab title; otherwise it uses that window's app name.
- [manual] If the selected window and its app have no useful name, the screenshot uses the timestamped default name.
- [manual] Save and Drag to Save use the same screenshot name with a PNG extension.
- [manual] Open Image uses the selected file's name in the Floating Editor title bar.
- [manual] Window captures and opened images show their name in the Floating Editor title bar; area and display captures show the timestamped default; reopening the last screenshot restores its name.
- [manual] Names remain local to Freeshots.

UX:
- Flow: capture an area or display for a timestamped name, capture a window for its window name, or open an image for its file name -> name appears in the Floating Editor title bar -> Save or Drag to Save uses that name; choose another name in the standard save panel if needed.
- Surface: title bar, providing persistent context for the current screenshot.
- States: area and display captures use a timestamp; window capture prefers the selected window title then its owning app name, and falls back to a timestamp; opened images use their file name; long names follow standard macOS title truncation.
- Words: “Screenshot Name”, title bar shows the current name, Save and Drag to Save prefill the same name.
- Access: title is exposed through the standard window title for VoiceOver; save panel filename remains editable with standard keyboard behavior.

### S-013 Show Freeshots in the app switcher while the Floating Editor is open

As the user, I can switch to the open screenshot editor with Command-Tab and quit Freeshots with Command-Q from the macOS app menu.

Acceptance:
- [manual] While the Floating Editor is open, Freeshots appears in the macOS app switcher.
- [manual] While the Floating Editor is open, the macOS menu bar shows the Freeshots app menu with Quit Freeshots and the Command-Q shortcut.
- [manual] Choosing Quit Freeshots or pressing Command-Q terminates Freeshots.
- [manual] Closing the Floating Editor returns Freeshots to its menu bar utility behavior while keeping the menu bar extra available.
- [manual] About and Settings windows can come in front of the Floating Editor when opened.

UX:
- Flow: open the Floating Editor -> switch to Freeshots with Command-Tab or choose Freeshots > Quit Freeshots / press Command-Q -> editor closes or app quits.
- Surface: standard macOS app menu, available while the editor is open.
- States: editor open makes Freeshots a regular app; closing the last window hides it from the app switcher and leaves the menu bar extra active.
- Words: “Freeshots”, “About Freeshots”, “Hide Freeshots”, “Quit Freeshots”.
- Access: Command-Tab uses the macOS app switcher; Quit Freeshots is available by keyboard and VoiceOver in the app menu.

### S-015 Start Freeshots at login

As the user, I can choose to have Freeshots start automatically when I log in.

Screens: 09-general-settings.png

Acceptance:
- [snap] General settings show the startup toggle, status, and any approval action without scrolling.
- [manual] General settings include a Start Freeshots at Login option that is off by default.
- [manual] Turning the option on registers Freeshots as a macOS login item; turning it off removes the registration.
- [manual] Freeshots shows whether the login item is enabled or requires approval, and provides a direct way to open the Login Items section of System Settings when approval is needed.
- [manual] After login, Freeshots starts as its menu bar utility without opening a capture or editor window.
- [manual] The preference and registration remain consistent after quitting and reopening Freeshots.

UX:
- Flow: Settings -> General -> turn on Start Freeshots at Login -> approve in System Settings if requested -> Freeshots starts at the next login; turn it off to remove the login item.
- Surface: Settings toggle, because it changes one persistent app preference.
- States: off; enabled; approval required with an Open Login Items Settings action; registration failure with a short explanation and retry guidance.
- Words: “Start Freeshots at Login”, “Open Login Items Settings”.
- Access: the toggle and settings link are keyboard accessible and VoiceOver labeled; the enabled or approval-required state is stated in text.

Status: doing

### S-016 Choose the interface appearance

As the user, I can have Freeshots follow macOS appearance or always use Light or Dark appearance.

Screens: 10-appearance-settings.png

Acceptance:
- [snap] Settings > Appearance offers System, Light, and Dark choices.
- [manual] System follows the current macOS appearance; Light and Dark keep Freeshots in the selected appearance.
- [manual] The selected appearance applies to the Floating Editor, Settings, and other Freeshots views, and remains selected after relaunch.
- [manual] System is selected by default for existing and new users.

UX:
- Flow: Settings -> Appearance -> select System, Light, or Dark -> Freeshots updates immediately; close Settings or choose another option.
- Surface: Appearance Settings tab, because this is a persistent app-wide preference.
- States: System is the default; Light and Dark apply immediately and remain selected after relaunch.
- Words: “Appearance”, “System”, “Light”, “Dark”.
- Access: native radio choices work by keyboard and VoiceOver; selection is not communicated by color alone.

Status: doing

## Later

- **V2:** Record a display, window, or area as a local video; preview and save or drag the clip. Audio, camera, and video editing scope remain undecided.

## Dropped

- Cloud uploads, share links, accounts, sync, analytics, and telemetry.
- Screenshot history/library, search, OCR, scrolling capture, and multi-image composition.

### S-014 Check Screen Recording access on first launch

As a new user, I can grant Screen Recording access before capturing, or skip and grant it later.

Acceptance:
- [manual] On first launch without Screen Recording access, Freeshots opens a permission window before the capture menu is used.
- [manual] The window explains why Screen Recording access is needed and opens the matching System Settings pane.
- [manual] The window checks for access while open and continues automatically after access is granted.
- [manual] Skip for Now closes the window and leaves capture available; attempting capture explains how to grant access.
- [manual] Freeshots does not show the first launch window again after access is granted or the user skips.
- [manual] Settings shows current Screen Recording access and includes Check Permissions Again and Open Screen Recording Settings actions.

UX:
- Flow: first launch without access -> permission window -> Open System Settings -> grant access -> window continues; or Skip for Now -> menu bar capture -> permission guidance if capture is attempted.
- Surface: first launch window, a short task that should complete or be skipped before continuing.
- States: missing access explains the reason and offers Open System Settings and Skip for Now; granted access confirms readiness and continues; closing while access is missing counts as skipping.
- Words: “Screen Recording Access”, “Allow Screen Recording”, “Open System Settings”, “Skip for Now”, “Screen Recording is ready”, “Continue”, “Check Permissions Again”.
- Access: Continue is the default action when access is granted; Escape skips; controls are keyboard navigable and VoiceOver labeled.
