#!/bin/bash
# update-appcast.sh - Prepends a new <item> to appcast.xml for Sparkle updates
# Usage: ./scripts/update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature]
#
# Example:
#   ./scripts/update-appcast.sh "1.2.3" "42" "build/Snapzy-v1.2.3.dmg" "appcast.xml" "abc123..."

set -euo pipefail

VERSION="${1:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature]}"
BUILD_NUMBER="${2:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature]}"
DMG_PATH="${3:?Usage: update-appcast.sh <version> <build_number> <dmg_path> [appcast_file] [ed_signature]}"
APPCAST_FILE="${4:-appcast.xml}"
ED_SIGNATURE="${5:-}"

if [ ! -f "$DMG_PATH" ]; then
  echo "::error::DMG file not found: $DMG_PATH"
  exit 1
fi

if [ ! -f "$APPCAST_FILE" ]; then
  echo "::error::Appcast file not found: $APPCAST_FILE"
  exit 1
fi

# Get file size in bytes
if [[ "$OSTYPE" == "darwin"* ]]; then
  FILE_SIZE=$(stat -f%z "$DMG_PATH")
else
  FILE_SIZE=$(stat -c%s "$DMG_PATH")
fi

# Generate RFC 2822 date
PUB_DATE=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')

# Download URL
DOWNLOAD_URL="https://github.com/duongductrong/Snapzy/releases/download/v${VERSION}/Snapzy-v${VERSION}.dmg"

# Release notes URL (GitHub Release page)
RELEASE_NOTES_URL="https://github.com/duongductrong/Snapzy/releases/tag/v${VERSION}"

# Build the new <item> block into a temp file
ITEM_FILE="${APPCAST_FILE}.item.tmp"
cat > "$ITEM_FILE" << EOF
    <item>
      <title>Version ${VERSION}</title>
      <sparkle:version>${BUILD_NUMBER}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:releaseNotesLink>
        ${RELEASE_NOTES_URL}
      </sparkle:releaseNotesLink>
      <enclosure
        url="${DOWNLOAD_URL}"
        sparkle:edSignature="${ED_SIGNATURE}"
        length="${FILE_SIZE}"
        type="application/octet-stream"/>
    </item>
EOF

# Insert new item after the <language> line (before existing items)
# Find the line number of <language> and insert after it
LANG_LINE=$(grep -n '<language>' "$APPCAST_FILE" | head -1 | cut -d: -f1)

if [ -z "$LANG_LINE" ]; then
  echo "::error::Could not find <language> tag in $APPCAST_FILE"
  rm -f "$ITEM_FILE"
  exit 1
fi

{
  head -n "$LANG_LINE" "$APPCAST_FILE"
  cat "$ITEM_FILE"
  tail -n +"$((LANG_LINE + 1))" "$APPCAST_FILE"
} > "${APPCAST_FILE}.tmp" && mv "${APPCAST_FILE}.tmp" "$APPCAST_FILE"

rm -f "$ITEM_FILE"

echo "Updated $APPCAST_FILE with v${VERSION} (build ${BUILD_NUMBER}, size ${FILE_SIZE} bytes)"
