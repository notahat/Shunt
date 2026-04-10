#!/bin/bash
# Usage: ./release.sh <version>
# e.g.   ./release.sh 1.0.0
#
# Prerequisites — run once to store notarization credentials in your keychain:
#   xcrun notarytool store-credentials "notarytool" \
#     --apple-id "your@apple.id" \
#     --team-id "EDZJE3T9P5" \
#     --password "xxxx-xxxx-xxxx-xxxx"  # app-specific password from appleid.apple.com

set -euo pipefail

VERSION=${1:?"Usage: $0 <version>"}

SCHEME="Shunt"
PROJECT="Shunt.xcodeproj"
TEAM_ID="EDZJE3T9P5"
ARCHIVE_PATH="build/Shunt.xcarchive"
EXPORT_PATH="build/export"
APP_PATH="$EXPORT_PATH/Shunt.app"
ZIP_PATH="build/Shunt-$VERSION.zip"

echo "==> Cleaning build directory"
rm -rf build
mkdir -p build

echo "==> Archiving"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH"

echo "==> Exporting with Developer ID signing"
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist build/ExportOptions.plist

echo "==> Zipping"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Notarizing (this may take a minute)"
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "notarytool" \
    --wait

echo "==> Stapling"
xcrun stapler staple "$APP_PATH"

echo "==> Re-zipping with stapled app"
rm "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Creating GitHub release v$VERSION"
gh release create "v$VERSION" "$ZIP_PATH" \
    --title "v$VERSION" \
    --generate-notes

echo "==> Done! https://github.com/notahat/Shunt/releases/tag/v$VERSION"
