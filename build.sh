#!/bin/zsh
set -euo pipefail

here=${0:A:h}
name="Freeshots"
config=release
[[ " $* " == *" --debug "* ]] && config=debug
scratch="${TMPDIR:-/tmp}/Freeshots-build"
version="${APP_VERSION:-0.1}"
build_number="${APP_BUILD:-$(date +%Y%m%d%H%M)}"
bundle_id="${APP_BUNDLE_ID:-com.l2fprod.freeshots}"
identity="${CODESIGN_IDENTITY:--}"

if [[ "${BUILD_UNIVERSAL:-0}" == "1" ]]; then
  for arch in arm64 x86_64; do
    arch_scratch="$scratch/$arch"
    swift build -c "$config" --package-path "$here" --scratch-path "$arch_scratch" --triple "$arch-apple-macosx26.0"
    bin_dir=$(swift build -c "$config" --package-path "$here" --scratch-path "$arch_scratch" --triple "$arch-apple-macosx26.0" --show-bin-path)
    mkdir -p "$here/build/$arch"
    cp "$bin_dir/$name" "$here/build/$arch/$name"
  done
  mkdir -p "$here/build"
  lipo -create "$here/build/arm64/$name" "$here/build/x86_64/$name" -output "$here/build/$name"
else
  swift build -c "$config" --package-path "$here" --scratch-path "$scratch"
  cp "$scratch/$config/$name" "$here/build/$name"
fi

app="$here/build/$name.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$here/build/$name" "$app/Contents/MacOS/$name"
sed -e "s/__VERSION__/$version/" -e "s/__BUILD__/$build_number/" -e "s/__BUNDLE_ID__/$bundle_id/" "$here/Info.plist.in" > "$app/Contents/Info.plist"

if [[ -f "$here/Resources/Assets.car" ]]; then
  cp "$here/Resources/Assets.car" "$app/Contents/Resources/"
fi
if [[ -f "$here/Resources/AppIcon.icns" ]]; then
  cp "$here/Resources/AppIcon.icns" "$app/Contents/Resources/"
fi

if [[ "$identity" == "-" ]]; then
  codesign --force --sign - "$app"
else
  codesign --force --sign "$identity" --options runtime --timestamp "$app"
fi
echo "built $app"
