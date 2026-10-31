# Freeshots

Freeshots is a native macOS screenshot utility. Product scope lives in [the brief](docs/BRIEF.md), and the implementation backlog lives in [the stories](docs/STORIES.md).

## Open in Xcode

Freeshots is a Swift package, which Xcode opens directly. Open `Package.swift` in Xcode, then choose the `Freeshots` scheme to build or run the app.

From Terminal:

```sh
open -a Xcode Package.swift
```

## Build an app bundle

```sh
./build.sh
```

The script builds `build/Freeshots.app` without installing or opening it.

## Install with Homebrew

Freeshots is distributed outside the Mac App Store through GitHub Releases and the `l2fprod/homebrew-tap` Homebrew tap:

```sh
brew install --cask l2fprod/tap/freeshots
```

Each branch has its own rolling prerelease. For example, pushes to `main` update [Freeshots main](https://github.com/l2fprod/freeshots/releases/tag/main), and pushes to a `dev` branch update [Freeshots dev](https://github.com/l2fprod/freeshots/releases/tag/dev). Each branch release includes a universal, signed, notarized ZIP from its latest successful build. Branch builds never update Homebrew.

To publish a stable Homebrew release, push a version tag such as `v0.2.0`. Tagged builds attach a versioned ZIP to a GitHub Release and update the Cask in the tap. Main builds never update Homebrew.

Before the first release, create a public `l2fprod/homebrew-tap` GitHub repository with a `Casks` directory. The workflow pushes the generated Cask there. Configure these Actions repository variables in Freeshots:

- `APP_BUNDLE_ID`: `com.l2fprod.freeshots`.
- `DEVELOPER_ID_APPLICATION_IDENTITY`: exact signing identity name from the Developer ID Application certificate, such as `Developer ID Application: Your Name (TEAMID)`.

Add these Actions repository secrets in Freeshots:

- `DEVELOPER_ID_APPLICATION_P12_BASE64`: base64 encoded Developer ID Application certificate exported as `.p12`.
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD`: password used when exporting the certificate.
- `APPLE_ID`: Apple ID email used for notarization.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for that Apple ID.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `HOMEBREW_TAP_TOKEN`: fine-grained GitHub token with Contents read/write access to `l2fprod/homebrew-tap`.

The app itself remains local-only: capture data is written only to the clipboard or files chosen by the user. GitHub Actions uses Apple’s notarization service to prepare externally distributed releases.
