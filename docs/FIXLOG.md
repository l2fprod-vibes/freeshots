# Fix log

## Screen Recording access was never requested

Symptom: Freeshots showed a Screen Recording message, but no prompt appeared and the app was absent from the Screen Recording list.

Cause: the capture path only called `CGPreflightScreenCaptureAccess()`, which checks access without requesting it.

Fix: call `CGRequestScreenCaptureAccess()` on the first capture attempt, expose a direct System Settings action after denial, and show live permission state in Settings.

Rule: always request Screen Recording access at capture time after a failed preflight; never treat a preflight check as a permission request.
