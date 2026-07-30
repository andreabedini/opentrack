#!/bin/sh

# exit when any command fails
set -e

APPNAME=opentrack

#macosx directory
dir="$1"
test -n "$dir"
# install directory
install="$2"
test -n "$install"
version="$3"
test -n "$version"
# macdeployqt, located by macosx/CMakeLists.txt. Qt does not put it on PATH, and
# with vcpkg it lives under <installed>/tools/Qt6/bin.
macdeployqt="$4"
test -n "$macdeployqt"
test -x "$macdeployqt"

app="$install/$APPNAME.app"
outdir="$(cd "$install/.." && pwd)"

tmp="$(mktemp -d "/tmp/$APPNAME-tmp.XXXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# Copy our own plist and set correct version
cp "$dir/Info.plist" "$app/Contents/"
sed -i '' -e "s#@OPENTRACK-VERSION@#$version#g" "$app/Contents/Info.plist"

# Copy PkgInfo
cp "$dir/PkgInfo" "$app/Contents/"

# Copy plugins
mkdir -p "$app/Contents/MacOS/Plugins"
cp -r "$install/Plugins" "$app/Contents/MacOS/"

# Use either of these, two of them at the same time will break things!
"$macdeployqt" "$app" -libpath="$install/Library"
#sh "$dir/install-fail-tool" "$app/Contents/Frameworks"

# Build iconset. sips and iconutil ship with macOS, unlike ImageMagick's convert
# which this used to shell out to.
sips -z 512 512 "$dir/../gui/images/opentrack.png" --out "$tmp/opentrack.png" >/dev/null
mkdir "$tmp/$APPNAME.iconset"
for spec in "16 icon_16x16" "32 icon_16x16@2x" "32 icon_32x32" "64 icon_32x32@2x" \
            "128 icon_128x128" "256 icon_128x128@2x" "512 icon_256x256@2x" "512 icon_512x512"
do
    # shellcheck disable=SC2086
    set -- $spec
    sips -z "$1" "$1" "$tmp/opentrack.png" --out "$tmp/$APPNAME.iconset/$2.png" >/dev/null
done
iconutil -c icns -o "$app/Contents/Resources/$APPNAME.icns" "$tmp/$APPNAME.iconset"

# The styled disk image needs create-dmg, which is not part of macOS. Skip it
# instead of failing a plain `cmake --install`; CI installs it so that tagged
# builds still get a .dmg.
if ! command -v create-dmg >/dev/null 2>&1; then
    echo "note: create-dmg not installed, skipping disk image" 1>&2
    exit 0
fi

# Only reference the extra folders that were actually installed, otherwise
# create-dmg fails on the missing path.
set --
if [ -d "$install/doc" ]; then
    set -- "$@" --add-folder "Document" "$install/doc" 20 40
fi
if [ -d "$install/xplane" ]; then
    set -- "$@" --add-folder "Xplane-Plugin" "$install/xplane" 420 40
fi
if [ -d "$install/thirdparty" ]; then
    set -- "$@" --add-folder "thirdparty" "$install/thirdparty" 620 40
fi

#Build DMG
#https://github.com/andreyvit/create-dmg
rm -f "$outdir/$version.dmg"
create-dmg \
  --volname "$APPNAME" \
  --volicon "$app/Contents/Resources/$APPNAME.icns" \
  --window-pos 200 120 \
  --window-size 800 450 \
  --icon-size 80 \
  --background "$dir/dmgbackground.png" \
  --icon "$APPNAME.app" 200 180 \
  --app-drop-link 420 180 \
  --hide-extension "$APPNAME.app" \
  --no-internet-enable \
  "$@" \
  "$outdir/$version.dmg" \
  "$app"

# Check if we have a DMG otherwise fail
if [ -f "$outdir/$version.dmg" ]; then
    ls -l "$outdir/$version.dmg"
else
    echo "Failed to create $outdir/$version.dmg" 1>&2
    exit 2
fi
