# Screenshot workflow additions

Research for Freeshots. Done 2026-11-08.

`[V]` is verified in a source; `[U]` is an open question or needs a product test.

## Research question

Which additions improve Freeshots' local screenshot capture and editing loop? Decision: define stories for timed capture, pixel crop, text extraction, and an About window with the requested AI Badge.

## Findings

- [V] macOS Screenshot already offers a timer before capture, supporting timed capture as a familiar Mac workflow. [Apple Support](https://support.apple.com/en-gb/guide/mac-mini/apdbc4019fdf/mac)
- [V] The local `screencapture(1)` manual documents `-T <seconds>` for delayed capture and `-i` for interactive selection. A recent macOS command guide describes `screencapture -i -T 3` as opening the selection immediately and delaying the screenshot after selection. [Guide to interactive capture and delay](https://atsum.in/mac/screencapture-interactive/)
- User direction: show a large five-second countdown; verify the overlay is absent from the captured pixels during implementation.
- [V] Cropping the screenshot pixels is distinct from Freeshots' current Aspect Ratio feature, which expands the surrounding canvas and does not crop the screenshot. [S-009](../STORIES.md#s-009-style-screenshots-and-markups)
- [V] Apple Vision's `VNRecognizeTextRequest` recognizes text in images, and Apple documents that Vision processing happens on-device. This supports an offline “Copy Text from Screenshot” action. [Recognizing Text in Images](https://developer.apple.com/documentation/vision/recognizing-text-in-images) [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [V] The AI Badge site describes the badge as a disclosure for AI imagery and suggests placement at the bottom-right when marking an image. It says the badge is freely usable and identifies the work as CC0 1.0. The badge repository offers PNG and SVG variants. [AI Badge](https://aibadge.org/) [Badge repository](https://github.com/jsit/aibadge)
- Product constraint: the Freeshots brief requires offline operation with no network requests. Bundle the badge rather than loading it from the site at runtime.

## Feature matrix

| Feature | Fit with Freeshots | Local/offline | Story |
|---|---|---:|---|
| Five-second visible countdown | Direct capture-flow improvement; fixed first version keeps controls simple | Yes | S-018 |
| Screenshot pixel crop | Completes the editor workflow and differs from canvas aspect ratio/padding | Yes | S-019 |
| Copy recognized screenshot text | Useful adjacent action; must protect redacted pixels | Yes, Vision on-device | S-020 |
| AI Badge in About Freeshots | Adds requested project disclosure and app identity | Yes, bundle the asset | S-021 |

## Decisions

1. Add one five-second timed option for each capture mode. Area/Window use interactive selection followed by the system's native delay, with a Freeshots countdown started on selection completion; Display uses the same prominent countdown before capture. Ensure the Freeshots overlay is absent from captured pixels.
2. Add a rectangular crop over screenshot pixels, with an undoable commit. Keep it separate from Aspect Ratio, backdrop, padding, and device frames.
3. Run text recognition locally and copy plain text. Apply the crop, Redact, and Blur marks before recognition; exclude added markup labels, styling frames, and backdrops.
4. Show a locally bundled AI Badge asset in About Freeshots, with visible source and CC0 1.0 attribution. Do not load the badge from a URL at runtime.

## Open questions

- [U] The aibadge.org page presents “Made with AI” as disclosure of AI imagery. Confirm the intended meaning when used in Freeshots' About window (AI assistance in the app/project, or disclosure of AI-created imagery used by the app).
- [U] Validate OCR reading order, language selection, latency, and redaction safety on real interface screenshots.
- [U] Confirm on macOS 26 that polling the global mouse-up event counter starts the Freeshots countdown only after area/window selection completes and that its timing stays aligned with `screencapture -i -T 5`.
- [U] Review the custom countdown across multiple displays.
- [U] Select the badge's color/transparent variant after reviewing it in the About window in Light and Dark appearances.
