# Freeshots design kit

## Feel

Three words: quick, crisp, expressive. Like a focused creative utility. Editor chrome uses macOS semantic surfaces and the user's system accent. Screenshot backdrops and markup color remain user-controlled content.

## Tokens

### Palette and meaning

| Meaning | Light | Dark | Use |
|---|---|---|---|
| `Ink.canvas` | `windowBackgroundColor` | `windowBackgroundColor` | Editor canvas surround |
| `Ink.surface` | `controlBackgroundColor` | `controlBackgroundColor` | Custom control surface |
| `Ink.text` | `primary` | `primary` | Main labels |
| `Ink.muted` | `secondary` | `secondary` | Supporting labels |
| `Ink.accent` | `accentColor` | `accentColor` | Focus and selected state |
| `Ink.selection` | `selectedContentBackgroundColor` | `selectedContentBackgroundColor` | Selected tool surface |
| `Ink.selectionText` | `selectedMenuItemTextColor` | `selectedMenuItemTextColor` | Selected tool symbol |
| `Ink.divider` | `separatorColor` | `separatorColor` | Separators |
| `Ink.warning` | `systemRed` | `systemRed` | Errors with icon and label |

### Scales

| Token | Value | Use |
|---|---:|---|
| `KitType.title` | system 20 pt semibold | Editor title |
| `KitType.body` | system 13 pt | Labels and controls |
| `KitType.meta` | system 11 pt | Dimensions and hints |
| `Metric.tool` | 30 pt square | Markup tool button |
| `Metric.actionHeight` | 32 pt | Copy and Save actions |
| `Metric.radius` | 10 pt | Tool and action controls |
| `Metric.panelRadius` | 18 pt | Floating editor chrome |
| `Metric.window` | 860 × 600 pt | Default editor size |
| `Motion.hover` | ease out 0.12 s | Hover surface |
| `Motion.press` | spring 0.20 s | Button press |

## Type and icons

Use the system font by role through `KitType`. Use `KitIcon` names in custom controls; SF Symbols are the initial source, light weight, 14 pt, one consistent optical size. Selected markup tools use a filled symbol where available.

## Window

The editor is a resizable floating utility window with hidden title text and visible traffic lights. The screenshot canvas sits beside a 272 pt inspector. The status item and macOS menus remain system controls.

## Parts

### Editor chrome

Header: 42 pt high; title on the left, standard traffic lights, drag area. Light/dark use `Ink.surface`; hover actions use `Ink.selection`.

### Markup tool button

30 × 30 pt, 10 pt radius, icon centered. Rest is transparent; hover uses a subtle `Ink.selection`; pressed scales to 0.97; selected uses `Ink.selection`; focused gets a 2 pt accent outline; disabled is 40% opacity. Same structure in light and dark.

### Action button

32 pt high, 10 pt radius. Use native system button styles for primary actions; secondary is `Ink.surface` with `Ink.text`; ghost is transparent until hover. Include rest, hover, pressed, focused, and disabled states in both appearances.

### Drag to Save handle

32 pt high, `Ink.surface`, 10 pt radius, custom drag glyph plus “Drag to Save”. Hover adds `Ink.selection`; dragging shows a ready cursor and preview; invalid destinations show a blocked cursor. Keep Save… available as a keyboard-accessible alternative.

### Screenshot canvas

Screenshot pixels are un-tinted and unfiltered. Add a 1 pt `Ink.divider` edge and soft system shadow; selected markup uses a lime outline with dark text/callouts for contrast.

### Capture overlay

Selection outline uses lime with a dark outer edge so it remains visible on any screen. Dimension label sits on an opaque graphite pill. Resting desktop remains unobscured; Reduce Transparency uses a solid surface.

## Accessibility

Every custom control remains a real SwiftUI `Button` or draggable transferable. Provide a label, keyboard action, VoiceOver name, and visible focus state. Pair warning/accent color with a symbol or word. Respect Reduce Motion and Increase Contrast.
