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
