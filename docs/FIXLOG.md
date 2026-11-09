# Fix log

## Screen Recording access was never requested

Symptom: Freeshots showed a Screen Recording message, but no prompt appeared and the app was absent from the Screen Recording list.

Cause: the capture path only called `CGPreflightScreenCaptureAccess()`, which checks access without requesting it.

Fix: call `CGRequestScreenCaptureAccess()` on the first capture attempt, expose a direct System Settings action after denial, and show live permission state in Settings.

Rule: always request Screen Recording access at capture time after a failed preflight; never treat a preflight check as a permission request.

## Device frame shadow darkened the window controls

Symptom: enabling Shadow made the traffic lights on a Window frame look darker.

Cause: the shadow was applied to the whole frame view, including its controls.

Fix: draw the shadow from the rounded frame silhouette underneath the controls.

Rule: always apply a device frame shadow to its rounded backing shape, not to the composed frame view.

## Fine Tune hid shadow controls when Shadow was off

Symptom: Shadow Blur and Shadow Opacity disappeared when Shadow was disabled, and the popover required scrolling to reach them.

Cause: disabled shadow settings were conditionally removed and the popover could size too short.

Fix: keep both sliders visible and disabled when Shadow is off, and give Fine Tune enough height to show all settings.

Rule: keep dependent appearance controls visible and disable them when their parent setting is off.

## Remembered screenshots exceeded the preferences size limit

Symptom: macOS logged that Freeshots attempted to store at least 4 MB in UserDefaults, and large screenshots could not be remembered reliably.

Cause: the full TIFF image was stored as a UserDefaults value.

Fix: store the TIFF under the app's local Application Support directory and keep only the screenshot name in UserDefaults; remove the obsolete image preference.

Rule: store screenshot bytes in a local file and reserve UserDefaults for small preferences and identifiers.

## Clipboard import menu state stayed disabled after Copy

Symptom: Open from Clipboard remained disabled after Copy placed an image on the clipboard.

Cause: the menu depended on a computed pasteboard check that SwiftUI did not observe for changes.

Fix: store clipboard image availability as observable state, refresh it after Freeshots copies an image and when the menu opens, and check again when importing.

Rule: refresh observable clipboard state after app writes and before clipboard actions; do not rely on an unobserved computed pasteboard value to redraw a menu.

## Crop selected the wrong screenshot region

Symptom: the crop selection moved correctly, but applying it showed a different part of the screenshot.

Cause: the normalized crop's top-origin Y coordinate was inverted when converting to CGImage pixel coordinates.

Fix: map the crop's `minY` directly to the CGImage pixel row, and keep the drag gesture in a named canvas coordinate space.

Rule: always convert crop coordinates using the target image API's documented origin; do not invert Y unless that API uses a bottom-origin coordinate system.
