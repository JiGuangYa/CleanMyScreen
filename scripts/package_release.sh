#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
LOCALIZATION_CODES_FILE="$ROOT_DIR/Localization/supported_localizations.txt"
RESOURCE_SOURCE_DIR="$ROOT_DIR/Sources/CleanMyScreenKit/Resources"
APP_NAME="CleanMyScreen"
APP_BUNDLE_ID="com.jiguang.CleanMyScreen"
APP_VERSION="${APP_VERSION:-1.0.0}"
APP_BUILD="${APP_BUILD:-1}"
ICON_MASTER="$DIST_DIR/AppIcon-1024.png"
ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg-root"
PKG_PATH="$DIST_DIR/$APP_NAME.pkg"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
ZIP_PATH="$DIST_DIR/$APP_NAME.zip"

rm -rf "$APP_DIR" "$ICONSET_DIR" "$DMG_STAGING_DIR" "$PKG_PATH" "$DMG_PATH" "$ZIP_PATH"
mkdir -p "$DIST_DIR" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

supported_localizations=(${(f)"$(<"$LOCALIZATION_CODES_FILE")"})

swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$ICON_MASTER"
mkdir -p "$ICONSET_DIR"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ICON_MASTER" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  retina_size=$(( size * 2 ))
  sips -z "$retina_size" "$retina_size" "$ICON_MASTER" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"

for resource_bundle in "$BIN_DIR"/*.bundle(N); do
  cp -R "$resource_bundle" "$APP_DIR/Contents/Resources/"
done

for localization_dir in "$RESOURCE_SOURCE_DIR"/*.lproj(N); do
  cp -R "$localization_dir" "$APP_DIR/Contents/Resources/"
done

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${APP_BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleLocalizations</key>
    <array>
$(for localization in "${supported_localizations[@]}"; do
  printf '        <string>%s</string>\n' "$localization"
done)
    </array>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null

codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
pkgbuild \
  --component "$APP_DIR" \
  --install-location "/Applications" \
  --identifier "$APP_BUNDLE_ID" \
  --version "$APP_VERSION" \
  "$PKG_PATH"

mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_DIR" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$ICON_MASTER" "$ICONSET_DIR" "$DMG_STAGING_DIR"

echo "Built artifacts:"
echo "  $APP_DIR"
echo "  $PKG_PATH"
echo "  $DMG_PATH"
echo "  $ZIP_PATH"
