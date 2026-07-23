#!/bin/bash
# Build Cryptonote.app from source, with the app icon and bundled fonts.
#
# Two variants control whether the 7 MB Chinese font is bundled.
#   bash app/package.sh          full build, includes Chinese (Han) scrambling
#   bash app/package.sh lite     lean build, Latin, Greek and Cyrillic only
#
# The app binary is identical in both. Only Cryptonote-CJK.ttf differs, so the
# lite build is about 7 MB smaller. Without that font, Chinese characters are
# not scrambled and stay readable, while every other script still works.
set -e
cd "$(dirname "$0")/.."          # repo root
ROOT="$(pwd)"
APP="$ROOT/Cryptonote.app"

VARIANT="${1:-full}"
if [ "$VARIANT" != "full" ] && [ "$VARIANT" != "lite" ]; then
  echo "Unknown variant '$VARIANT'. Use 'full' (default) or 'lite'." >&2
  exit 1
fi

echo "Compiling..."
swiftc app/main.swift -o app/cryptonote-bin -framework Cocoa -framework CoreText

echo "Generating app icon from assets/cryptonote-icon.png..."
ICONSET="$(mktemp -d)/Cryptonote.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s assets/cryptonote-icon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d assets/cryptonote-icon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o assets/Cryptonote.icns

echo "Assembling bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp app/cryptonote-bin "$APP/Contents/MacOS/Cryptonote"
cp Cryptonote.ttf "$APP/Contents/Resources/Cryptonote.ttf"
cp assets/Cryptonote.icns "$APP/Contents/Resources/Cryptonote.icns"
if [ "$VARIANT" = "full" ]; then
  cp Cryptonote-CJK.ttf "$APP/Contents/Resources/Cryptonote-CJK.ttf"   # +7 MB, Chinese
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Cryptonote</string>
  <key>CFBundleDisplayName</key><string>Cryptonote</string>
  <key>CFBundleIdentifier</key><string>com.cryptonote.scratchpad</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>Cryptonote</string>
  <key>CFBundleIconFile</key><string>Cryptonote</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
</dict></plist>
PLIST

touch "$APP"
SIZE=$(du -sh "$APP" | cut -f1)
echo "Built $APP  (variant: $VARIANT, size: $SIZE)"
