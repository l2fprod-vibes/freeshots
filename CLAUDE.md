# Freeshots

Native macOS screenshot utility. Product scope and acceptance criteria live in `docs/BRIEF.md` and `docs/STORIES.md`; shared product terms live in `docs/GLOSSARY.md`.

Use only BAMA skills for work in this repository. Do not invoke workflows from Superpowers or other skill collections.

## Product constraints

- V1 captures and marks up screenshots; local copy, save, and drag-to-file are the output paths.
- Video recording is planned for v2.
- Captures stay on the Mac. Do not add uploads, sync, telemetry, analytics, or network requests.
- The app is a menu bar utility with a floating editor, not a screenshot library.

## Build

Run `./build.sh`. The script builds a local `.app` bundle in `build/` and does not install or open it.

## Icon

The Icon Composer source is `Icon/AppIcon.icon`. Use `tools/make_icon.sh` to compile it and `tools/icon_review.sh` to render the icon looks.

Design rules: `design/DESIGN-SYSTEM.md`. Use its tokens; never hard-code colors, radii, or durations.
