#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="PillingApp"
PROJECT="$PROJECT_DIR/PillingApp.xcodeproj"
ARCHIVE_PATH="$PROJECT_DIR/build/PillingApp.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
P8_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/AuthKey_A9K4ALJZ5U.p8"
KEY_ID="A9K4ALJZ5U"
ISSUER_ID="9d4fd887-b25b-4da1-9a29-501884a165ef"

echo "▶ Archive 시작..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=557346W8SC \
  | xcpretty || true

echo "▶ IPA 내보내기..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$PROJECT_DIR/ExportOptions.plist"

IPA_PATH=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
echo "▶ IPA: $IPA_PATH"

echo "▶ TestFlight 업로드 중..."
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER_ID" \
  --verbose

echo "✅ 업로드 완료!"
