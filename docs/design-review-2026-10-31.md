# Freeshots Apple design review

## Summary

Freeshots is a macOS screenshot utility whose main job is to get people from capture to an edited local image quickly. The menu bar extra and floating editor fit that job; its strongest visual moment is the screenshot canvas alongside compact markup tools. Initial rating: **Needs work**. Post-change rating: **Good**. The app now better follows macOS color, focus, and progressive disclosure conventions, but this review does not claim perfect guideline compliance: only the editor preview was visually captured; the menu and Settings window were reviewed from source rather than snapshots.

## Follow-up

The user rejected the inspector direction. The editor now uses a full-width canvas with a compact toolbar and on-demand Appearance popover; see [editor-redesign-2026-10-31.md](editor-redesign-2026-10-31.md) for the updated rationale and function map. The export correction and toolbar redesign supersede the implementation notes below.

## Initial review and recommendations

### High — The inspector competed with the screenshot

The inspector was fixed at 304 pt and presented every backdrop slider and shadow control at once. That reduced room for the image and made the inspector feel like a settings form instead of a quick editing palette.

Apple recommends progressive disclosure when a view presents too many choices (`layout.md` › Best practices: “Use progressive disclosure to make layouts cleaner and easier to interact with.”).

**Recommendation:** narrow the inspector and tuck lower-frequency geometry and shadow sliders into a disclosure while keeping export actions, markup tools, backdrop presets, aspect ratio, and frame selection visible.

### High — Focus feedback was disabled for the editor

The root editor view used `.focusEffectDisabled()`, which could hide keyboard focus feedback from custom controls and hinder Full Keyboard Access.

Apple describes accessible interfaces as adaptable to how people use their devices and points to keyboard navigation in its accessibility guidance (`accessibility.md` › Overview).

**Recommendation:** remove the root suppression and keep all custom tool controls as keyboard-accessible buttons with VoiceOver labels and visible focus states.

### Medium — App chrome used fixed graphite, lime, and gray values

The editor chrome had a custom light/dark palette even though the product brief calls for the user's Mac accent. This made selection and focus look different from the rest of macOS, and the fixed lime accent did not adapt to the selected system accent.

Apple says system-defined colors adapt to appearance and accessibility settings (`color.md` › Best practices).

**Recommendation:** use semantic AppKit colors for surfaces, labels, separators, warning, and selected tool states. Preserve user-defined markup colors and backdrop colors because those style the image, not app chrome.

### Medium — Selected state needed a non-color cue

Markup and backdrop choices indicated selection mainly through a colored surface or border. A selected tool should also be announced as selected to assistive technology.

**Recommendation:** pair macOS’s selected foreground/background colors and expose the selected trait to VoiceOver.

## Changes implemented

- Reduced inspector width from 304 pt to 272 pt.
- Grouped padding, corner, and shadow controls inside a collapsed “Fine Tune” disclosure. All controls remain available; the core editor workflow stays visible.
- Switched editor chrome and tool selection to semantic macOS colors, including the paired selected foreground.
- Removed `.focusEffectDisabled()` and exposed selected state for markup and backdrop choices.
- Clarified the reset action as “Reset Appearance,” since it restores the complete appearance configuration.
- Updated the design kit docs to describe the current system-color approach.

The menu bar extra remains a menu, as Apple recommends for menu bar extras (`the-menu-bar.md` › Menu bar extras: “Display a menu — not a popover — when people click your menu bar extra.”). Capture modes, Open Image, Settings, and Quit remain available there, with Command-O, Command-Comma, and Command-Q. Settings remains in the `Settings` scene; its grouped form is suitable for the current single pane. No capture, markup, copy, save, drag, preference, or local data behavior was changed.

## Post-change review

### What works

- The product’s menu bar entry point matches its utility role. A symbol-only menu bar extra and a menu-style presentation are appropriate.
- The editor keeps the screenshot as the dominant content and retains Copy, Save, drag-to-save, Undo, Redo, markup, and appearance controls in the inspector.
- The inspector is denser without hiding its core workflow. The less frequently used sliders are one disclosure away.
- System semantic colors now follow macOS appearance and accent choices; selected tool glyphs use the system selected-menu foreground.
- Settings uses a grouped native form, Command-Comma, and a system permission settings link. Shortcuts and local-only preference controls remain intact.
- Existing labels and tooltips cover icon-only editor actions.

### Improvements

- **Medium — Verify the menu and Settings visually in both appearances.** The repository has no menu/settings snapshot flow. The final editor preview was inspected at `/tmp/freeshots-editor-final.png`; Settings and menu behavior were checked from source, not rendered screenshots. The relevant HIG patterns are `settings.md` › Desktop (macOS) and `the-menu-bar.md` › Best practices.
- **Low — Consider an inspector visibility command if the editor later gains more controls.** A hide/show route would give the screenshot more room on smaller windows, but the current product story calls for a persistent inspector and the revised width addresses the immediate crowding. Apple recommends considering hideable panes when they help editing (`split-views.md` › Best practices).
- **Low — Audit keyboard shortcuts in a running app with text editing active.** Copy and Save intentionally use standard Command-C and Command-S, while tool shortcuts are unmodified characters. The current core test suite exercises appearance/export logic, not the full event routing path.

### Craft notes

The distinguishing feature is the screenshot itself: it remains large, editable, and locally deliverable. System color in editor chrome gives the image and user-selected backdrop room to carry the personality. The inspector still has a custom visual language, but its layout is now more restrained and platform-aligned.

## Verification

- `./build.sh --debug` — passed.
- `swift test` — 8 tests passed, 0 failures.
- Built-in editor preview captured and inspected at `/tmp/freeshots-editor-final.png`.
- `git diff --check` and `git diff --cached --check` — passed after the final edits.
- No menu/settings snapshot, live capture, or end-to-end UI harness exists in this repository, so those interactions were not visually or interactively exercised here.
