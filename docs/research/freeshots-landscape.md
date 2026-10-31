# Mac screenshot and quick recording tools

Research for Freeshots. Done 2026-10-31.

`[V]` verified in a source; `[K]` from experience/knowledge; `[U]` unverified and must be tested.

## Research question

What should Freeshots borrow from modern screenshot and screen-recording tools to make capture, markup, and local file delivery feel like one fast, polished Mac workflow? This informs the first release feature set.

## Market snapshot

| App | Platform and pricing model | Relevant strengths |
|---|---|---|
| Skitch | Mac; current price not clear in the retrieved listing | Familiar, focused screenshot capture and markup: arrows, shapes, callouts, pixelation, highlights. [V](https://apps.apple.com/us/app/skitch-snap-mark-up-share/id425955336?mt=12) |
| Monosnap | Mac and Windows; free tier and paid monthly plans | Screenshot and video capture, annotation, uploads, and cloud integrations. [V](https://monosnap.com/pay) |
| CleanShot X | Mac; Basic license and Pro subscription options | Capture, annotation, scrolling capture, recording, quick-access overlay, video editing, and optional cloud. [V](https://cleanshot.com/pricing) |
| Shottr | Mac; usable free, paid license for additional features | Lightweight capture, editable markup, scrolling captures, OCR, pinning, backdrops, and S3 uploads. [V](https://shottr.cc/) |
| Snagit | Mac and Windows; paid product | Screenshot and video capture, extensive markup, scrolling capture, OCR, and integrations. [V](https://www.techsmith.com/snagit/) |

## Findings

- [V] Monosnap puts capture in the menu bar. Its selection flow supports area, full-screen, and repeat-area capture; modifiers can switch to video, add a timer, move the selection, or constrain it to a square. [Screenshot guide](https://monosnap.zendesk.com/hc/en-us/articles/360017530380-Mac-How-to-take-screenshots)
- [V] Monosnap follows capture with a compact editor or recorder: annotate/blur/copy/save/upload stills; pause/resume and choose cursor, clicks, webcam, and audio for video; then preview, trim, rename, save, or upload. [Video guide](https://monosnap.zendesk.com/hc/en-us/articles/360017530440-Mac-How-to-record-videos) [First screenshot guide](https://monosnap.zendesk.com/hc/en-us/articles/360019602719-How-to-take-and-upload-the-first-screenshot)
- [V] CleanShot uses an All-in-One capture entry point and Quick Access Overlay for recent results. Its current plans pair screenshots and recording with annotation; video editing and animated zooms are included in the newer Studio workflow. Cloud is optional for local app use. [Features](https://cleanshot.com/features) [Pricing and FAQ](https://cleanshot.com/pricing)
- [V] Shottr emphasizes lightweight operation and object-based edits: annotations, OCR/QR reading, scrolling screenshots, screenshot composition, pinning, rulers, color sampling, and styled backdrops. [Features and changelog](https://www.shottr.cc/)
- [V] Skitch's documented markup includes arrows, lines, shapes, text, stamps, pen, highlighter, pixelation, crop, and undo/redo. [Evernote help](https://help.evernote.com/hc/en-us/articles/209005587-Annotate-images-and-PDFs)
- [V] Apple's ScreenCaptureKit provides screenshot and streaming capture APIs. Apple recommends the system content picker for choosing displays, apps, or windows; recording requires the relevant macOS privacy authorization. [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit) [WWDC23 picker session](https://developer.apple.com/videos/play/wwdc2023/10053/) [ScreenCaptureKit updates](https://developer.apple.com/documentation/updates/screencapturekit)
- [V] For new macOS development, ScreenCaptureKit is preferable to deprecated `CGWindowListCreateImage`; microphone and camera options have separate authorization requirements. [Deprecated API](https://developer.apple.com/documentation/coregraphics/cgwindowlistcreateimage) [Media capture authorization](https://developer.apple.com/documentation/bundleresources/requesting-authorization-for-media-capture-on-macos)

## Likes and dislikes

| App | People like | People dislike / gaps | Sources |
|---|---|---|---|
| Skitch | Simple markup; quick repeat capture for consistent documentation. | Reports of aging maintenance, shortcut conflicts, and slowdowns with large Evernote notebooks. | [App Store reviews](https://apps.apple.com/us/app/skitch-snap-mark-up-share/id425955336?mt=12&platform=mac&see-all=reviews) |
| Monosnap | People recommend it for quick annotation and recording; official guides confirm those flows. | Recent review evidence is sparse, so current pain points remain unknown. [U] | [User discussion](https://www.reddit.com/r/macapps/comments/lgh8yo) · [official video guide](https://monosnap.zendesk.com/hc/en-us/articles/360017530440-Mac-How-to-record-videos) |
| CleanShot X | Frequently used capture, scrolling screenshots, annotation, and recording. | Price/update charges and a feeling of excess for simple workflows recur in discussions. | [Feature discussion](https://www.reddit.com/r/macapps/comments/1jur1n1/what_cleanshot_x_features_do_you_actually_use/) · [pricing discussion](https://www.reddit.com/r/macapps/comments/1w5wgfu/any_actually_good_free_alternatives_to_cleanshot/) |
| Shottr | Lightweight, fast, annotation and measurement tools; users cite its low-cost model. | Scrolling-capture reliability is a reported concern; feature requests also show demand for history, privacy controls, and easier customization. | [Product/release notes](https://www.shottr.cc/) · [feature requests](https://www.shottr.cc/request/) · [discussion](https://www.reddit.com/r/macapps/comments/1rfyugm/shottr_vs_cleanshot_x_in_2026_which_one_are_you/) |
| Snagit | Users value clear direct markup and robust video capture. | Price and subscription model draw objections; some users report permission friction and slow loading. | [User discussion](https://www.reddit.com/r/instructionaldesign/comments/1osvlte/is_snagit_best_in_class_for_quick_content_grabs/) · [G2 reviews](https://www.g2.com/products/snagit/reviews) · [permission issue](https://www.reddit.com/r/SnagIt/comments/1fo2fr3/error_snagit_2024app_would_like_to_access_data/) |

## Feature matrix

| Feature | Skitch | Monosnap | CleanShot X | Shottr | Snagit | Freeshots v1? |
|---|---:|---:|---:|---:|---:|---|
| Area/window/full-display capture with hotkeys | Yes | Yes | Yes | Yes | Yes | Yes |
| Fast markup: arrows, shapes, text, blur/pixelate | Yes | Yes | Yes | Yes | Yes | Yes |
| Video recording with pause/stop controls | — | Yes | Yes | Not a core feature | Yes | No (planned v2) |
| Copy/save/drag out locally | Yes | Yes | Yes | Yes | Yes | Yes |
| Upload and share a link | Evernote flow | Yes | Optional cloud | S3 upload | Screencast/integrations | No (local-only) |
| Scrolling capture, OCR, advanced video effects | Partial/no | Some | Yes | Yes (scroll/OCR) | Yes | Later, unless research/user changes scope |

## Decisions to carry into the brief

1. Keep the v1 capture workflow centered on screenshots. The user has placed video recording in v2; Monosnap and CleanShot remain references for that later milestone. [V](https://monosnap.zendesk.com/hc/en-us/articles/360017530380-Mac-How-to-take-screenshots) [V](https://cleanshot.com/features)
2. Put the immediate result first: copy, save, drag, and open for markup should be obvious after capture. This preserves Skitch's focused feel and Monosnap's short route from capture to delivery. [V](https://help.evernote.com/hc/en-us/articles/209005587-Annotate-images-and-PDFs) [V](https://monosnap.zendesk.com/hc/en-us/articles/360019602719-How-to-take-and-upload-the-first-screenshot)
3. Keep annotations editable until export, and make blur/redaction dependable. Leading editors preserve object-level editing; sensitive-data masking appears in both feature sets and user requests. [V](https://shottr.cc/) [V](https://www.shottr.cc/request/)
4. Build screenshot capture with current Apple capture APIs. Revisit ScreenCaptureKit recording and its extra permissions when v2 video work begins. [V](https://developer.apple.com/documentation/screencapturekit) [V](https://developer.apple.com/documentation/bundleresources/requesting-authorization-for-media-capture-on-macos)
5. Keep the first interface focused. Competitors have deep feature sets, but user feedback supports a clear quick path for occasional annotation and a more capable editor when needed. [V](https://www.reddit.com/r/macapps/comments/1w5wgfu/any_actually_good_free_alternatives_to_cleanshot/) Planned test: validate the proposed capture-to-result flow with a small interactive prototype before locking the UI.

## Open questions

- [U] For v2 video, decide whether recordings include system audio, microphone, webcam, GIF, or some combination. Prototype the permission and start/stop flow on the target macOS version.
- [U] What visual direction does “modern/cool” mean to the user? Bring moodboard/mockup options into design exploration before implementation.
