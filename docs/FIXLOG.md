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
