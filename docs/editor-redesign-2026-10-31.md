# Floating Editor redesign

## Goal

Freeshots is used to inspect and mark up an image, then deliver it locally. The screenshot should take the space; tools should be easy to find without competing with the image.

## Options considered

1. **Keep and narrow the inspector.** This preserves the familiar arrangement but still permanently spends canvas width and keeps the app feeling like a settings panel.
2. **Make the inspector hideable.** This helps when people need more canvas, but introduces another panel state, shortcut, and reveal path while retaining the same panel-heavy layout whenever open.
3. **Use a compact toolbar and an Appearance popover.** Keep frequent markup, history, color, and delivery actions visible. Show backdrop, ratio, frame, and detailed styling only while someone changes appearance. This preserves the full image width and follows macOS toolbar and popover patterns.

**Chosen:** option 3. Appearance changes are occasional, while selecting tools and exporting are repeated actions. One click to open the Appearance popover is a reasonable tradeoff for a larger, calmer work surface.

## Layout

```text
┌───────────────────────────────────────────────────────────────────────┐
│ Select Arrow Shape Text Pen Redact Blur Color │ Undo Redo   Appearance │ Copy Save Drag │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│                    Full-width screenshot work surface                │
│                                                                       │
├───────────────────────────────────────────────────────────────────────┤
│ Inline status or Screen Recording permission message                 │
└───────────────────────────────────────────────────────────────────────┘
```

The appearance popover is 320 pt wide and contains backdrop presets, aspect ratio, device frame, and Fine Tune controls. The frequent toolbar remains visible when the popover closes. Selected text marks expose their text field in the toolbar, next to the tools that create and edit them.

## Function map

| Function | Location after redesign |
|---|---|
| Select, arrow, shape, text, pen, redact, blur | Leading toolbar group |
| Markup color and selected mark text | Toolbar, shown when relevant |
| Remove selected mark | Toolbar, shown when relevant |
| Undo and Redo | Toolbar history group |
| Backdrop, aspect ratio, device frame, padding, corners, shadow | Appearance popover |
| Copy, Save, Drag to Save | Trailing toolbar group |
| Capture permission/error and export feedback | Inline status beneath the canvas |

## Delight and craft

The image is the hero. A quiet, familiar Mac toolbar frames it, and the colorful screenshot composition provides the expressive moment. No new palette, permanent panel, or decorative chrome is needed. The style popover uses progressive disclosure while keeping every control one click away.

## Export consistency

Copy, Save, and Drag to Save all call `ScreenshotExport.pngData`. The editor’s interactive SwiftUI canvas still supports direct manipulation; exported frame details must stay visible outside the image clip. `ScreenshotRenderer` now saves and restores a dedicated Core Graphics state around the clipped screenshot and markup so title-bar controls are not clipped out.
