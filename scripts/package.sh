#!/bin/bash
# Builds a universal KeyFlip.app and wraps it in dist/KeyFlip-<version>.pkg
set -euo pipefail

VERSION="${1:-$(cat "$(dirname "$0")/../VERSION")}"
IDENTIFIER="io.github.mohamedsawahzc.keyflip"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/root/KeyFlip.app"

cd "$ROOT"

# 1) Compile a universal release binary
swift build -c release --arch arm64 --arch x86_64

# 2) Assemble the app bundle
rm -rf build dist
mkdir -p "$APP/Contents/MacOS" dist
cp .build/apple/Products/Release/KeyFlip "$APP/Contents/MacOS/KeyFlip"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"

# 3) Render the icon at every size macOS asks for
ICONSET=build/AppIcon.iconset
mkdir -p "$ICONSET" "$APP/Contents/Resources"
swift scripts/make-icon.swift build/icon.png
for SIZE in 16 32 128 256 512; do
  sips -z $SIZE $SIZE build/icon.png --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
  sips -z $((SIZE * 2)) $((SIZE * 2)) build/icon.png --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# 4) Strip Finder metadata, then ad-hoc sign so Apple Silicon will run it
xattr -cr "$APP"
codesign --force --sign - "$APP"

# 5) Build the installer, always into /Applications
pkgbuild --analyze --root build/root build/components.plist
plutil -replace 0.BundleIsRelocatable -bool NO build/components.plist
pkgbuild --root build/root --component-plist build/components.plist \
  --install-location /Applications \
  --identifier "$IDENTIFIER" --version "$VERSION" \
  "dist/KeyFlip-$VERSION.pkg"

echo "dist/KeyFlip-$VERSION.pkg"
