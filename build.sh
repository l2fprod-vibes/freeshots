#!/bin/zsh
set -euo pipefail

here=${0:A:h}
name="Freeshots"
config=release
[[ " $* " == *" --debug "* ]] && config=debug
scratch="${TMPDIR:-/tmp}/Freeshots-build"

swift build -c "$config" --package-path "$here" --scratch-path "$scratch"

app="$here/build/$name.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$scratch/$config/$name" "$app/Contents/MacOS/$name"
sed -e "s/__BUILD__/$(date +%Y%m%d%H%M)/" "$here/Info.plist.in" > "$app/Contents/Info.plist"

if [[ -f "$here/Resources/Assets.car" ]]; then
  cp "$here/Resources/Assets.car" "$app/Contents/Resources/"
fi
if [[ -f "$here/Resources/AppIcon.icns" ]]; then
  cp "$here/Resources/AppIcon.icns" "$app/Contents/Resources/"
fi

codesign --force --sign - "$app"
echo "built $app"
