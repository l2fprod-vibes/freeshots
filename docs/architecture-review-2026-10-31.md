# Architecture review — 2026-10-31

## Screen capture and authorization  [Strong]

Files: `Sources/Freeshots/App.swift`, `Sources/Freeshots/ScreenCaptureService.swift`

Signal: the capture coordinator was handling panel state, user permission, a subprocess, temporary files, and result state.

Problem: a capture API or permission change would have to be edited inside the editor workflow, where it could also affect panel restoration and pending markup.

Proposal: keep one narrow OS boundary: `func capture(_ mode: CaptureMode) async throws -> NSImage?`. The service owns authorization, temporary files, and the local capture process; the coordinator maps results to editor state.

Benefits: capture platform details stay local, and permission denial has one typed result that the UI can explain.

Proof of same behavior: the app builds in Swift 6 after extraction. No automated tests or visual snapshots were run in this pass.

Plan: extract the service, leave coordinator state and editor behavior in place, then build.

## Top recommendation

The capture boundary was extracted to `ScreenCaptureService`. Keep future ScreenCaptureKit work behind this interface.

## Considered, not recommended

- Split `MarkupDocument`: it is small and already keeps annotation history separate from capture orchestration.
- Add a persistence layer: screenshots are intentionally temporary until the user copies, saves, or drags them.
