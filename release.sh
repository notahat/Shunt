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

echo "==> Tagging v$VERSION"
git tag "v$VERSION"
git push origin "v$VERSION"

echo "==> Creating GitHub release v$VERSION"
gh release create "v$VERSION" "$ZIP_PATH" \
    --title "v$VERSION" \
    --generate-notes

echo "==> Updating Homebrew tap"
SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
TAP_DIR=$(mktemp -d)
git clone git@github.com:notahat/homebrew-tap.git "$TAP_DIR"
sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$TAP_DIR/Casks/shunt.rb"
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$TAP_DIR/Casks/shunt.rb"
git -C "$TAP_DIR" commit -am "Update Shunt to v$VERSION"
git -C "$TAP_DIR" push
rm -rf "$TAP_DIR"

echo "==> Done! https://github.com/notahat/Shunt/releases/tag/v$VERSION"
