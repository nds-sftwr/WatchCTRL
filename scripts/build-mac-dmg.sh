#!/bin/bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────
APP_NAME="WatchCTRL Mac"
SCHEME="WatchCTRL Mac"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_NAME="WatchCTRL-Mac.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DOCS_DIR="$PROJECT_DIR/docs"

# Notarization credentials — set these env vars or they'll be prompted
# APPLE_ID: your Apple ID email
# APPLE_TEAM_ID: your team ID (P7MHD6K252)
# APPLE_APP_PASSWORD: app-specific password (generate at appleid.apple.com)
#   Store it in keychain: xcrun notarytool store-credentials "notarytool-profile" \
#     --apple-id "you@email.com" --team-id "P7MHD6K252" --password "xxxx-xxxx-xxxx-xxxx"

echo "═══════════════════════════════════════════"
echo "  Building $APP_NAME DMG"
echo "═══════════════════════════════════════════"

# ─── Clean ───────────────────────────────────────────────────────────
echo ""
echo "▸ Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ─── Archive ─────────────────────────────────────────────────────────
echo "▸ Archiving..."
xcodebuild archive \
    -project "$PROJECT_DIR/WatchCTRL Mac.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="P7MHD6K252" \
    CODE_SIGN_STYLE=Automatic \
    | tail -5

echo "  ✓ Archive created"

# ─── Export ──────────────────────────────────────────────────────────
echo "▸ Exporting..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$PROJECT_DIR/scripts/ExportOptions.plist" \
    | tail -5

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "  ✗ Export failed — app not found at $APP_PATH"
    exit 1
fi
echo "  ✓ App exported"

# ─── Create DMG ──────────────────────────────────────────────────────
echo "▸ Creating DMG..."
# Create a temporary folder with the app and Applications symlink
DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "WatchCTRL Mac" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"
echo "  ✓ DMG created at $DMG_PATH"

# ─── Notarize ────────────────────────────────────────────────────────
echo "▸ Submitting for notarization..."
echo "  (This may take a few minutes...)"

# Try stored credentials first, fall back to env vars
if xcrun notarytool history --keychain-profile "notarytool-profile" &>/dev/null; then
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "notarytool-profile" \
        --wait
else
    if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_APP_PASSWORD:-}" ]; then
        echo ""
        echo "  ⚠ No stored credentials found. Set up with:"
        echo "    xcrun notarytool store-credentials \"notarytool-profile\" \\"
        echo "      --apple-id \"you@email.com\" \\"
        echo "      --team-id \"P7MHD6K252\" \\"
        echo "      --password \"xxxx-xxxx-xxxx-xxxx\""
        echo ""
        echo "  Or set APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_PASSWORD env vars."
        echo ""
        echo "  Skipping notarization. You can notarize manually with:"
        echo "    xcrun notarytool submit \"$DMG_PATH\" --keychain-profile \"notarytool-profile\" --wait"
        echo "    xcrun stapler staple \"$DMG_PATH\""
        echo ""
        echo "  DMG is ready at: $DMG_PATH"
        exit 0
    fi
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "${APPLE_TEAM_ID:-P7MHD6K252}" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
fi

echo "  ✓ Notarization complete"

# ─── Staple ──────────────────────────────────────────────────────────
echo "▸ Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"
echo "  ✓ Stapled"

# ─── Copy to docs ────────────────────────────────────────────────────
echo "▸ Copying DMG to docs/ for GitHub Pages..."
mkdir -p "$DOCS_DIR"
cp "$DMG_PATH" "$DOCS_DIR/$DMG_NAME"
echo "  ✓ Copied to $DOCS_DIR/$DMG_NAME"

echo ""
echo "═══════════════════════════════════════════"
echo "  ✓ Done! DMG ready at:"
echo "    $DOCS_DIR/$DMG_NAME"
echo "═══════════════════════════════════════════"
