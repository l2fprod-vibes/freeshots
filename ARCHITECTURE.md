# Architecture

## Targets

- `Freeshots` is one Swift Package executable and one menu bar app. There are no extensions or external dependencies.

## Layers

- `App.swift` owns SwiftUI scenes, the floating panel, and capture workflow state.
- `ScreenCaptureService.swift` owns Screen Recording authorization and the local macOS capture process.
- `Hotkeys.swift` owns Carbon global shortcut registration, shortcut preferences, and the shortcut recorder control.
- `Markup.swift` owns annotation state, undo/redo, hit testing, and the editor canvas.
- `ScreenshotRenderer.swift` flattens annotations into exportable PNG pixels.
- `ScreenshotDragView.swift` supplies PNG file promises to Finder and other local drop targets.
- `DesignKit/` and `UI/` contain reusable visual components and tokens.

## Dependency direction

Views and `CaptureCoordinator` depend on feature modules. Feature modules do not depend on app scenes. `ScreenshotRenderer` accepts an image and annotation values; it does not read app state. The app uses only system frameworks and local file/clipboard APIs.

## Seams

- `ScreenCaptureService.capture(_:)` is the OS capture boundary.
- `ScreenshotRenderer.pngData(image:annotations:)` is the output boundary for clipboard, save, and drag.
- `HotkeyCenter` is the Carbon shortcut boundary.
