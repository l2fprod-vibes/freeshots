# Freeshots design system

Freeshots uses the macOS accent for standard menus and controls. The custom floating editor and markup tools use the Freeshots palette in `design/KIT.md`.

## `Sources/Freeshots/UI/Theme.swift`

- `NativeTheme.accent` follows `Color.accentColor` for system controls; do not override the user's Mac accent there.
- Do not add an app-specific light/dark switch. The app follows the Mac appearance.

## Surfaces and controls

- Use system menus, save panels, buttons, and text fields.
- Use the custom meaning tokens in `DesignKit/KitTokens.swift` for editor chrome and markup tools.
- Keep screenshot pixels unmodified until the user adds markup.

## Layout and motion

- Align editor controls to a 4 pt spacing rhythm; keep related tools close and separate export actions from markup tools.
- Use system transitions by default. Respect Reduce Motion and Reduce Transparency for any custom capture overlay.

## Icons and accessibility

- Use SF Symbols for menu and editor actions; label icon-only controls with a tooltip and VoiceOver name.
- Pair status colors with a word or symbol. Keep screenshot pixels and markup easy to distinguish in light and dark appearance.
