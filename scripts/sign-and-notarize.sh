#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-WaterMascot}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
APP_PATH="${APP_PATH:-${OUTPUT_DIR}/${APP_NAME}.app}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${OUTPUT_DIR}/${APP_NAME}.zip}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
TEAM_ID="${TEAM_ID:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ABS_APP_PATH="${ROOT_DIR}/${APP_PATH}"
ABS_ARCHIVE_PATH="${ROOT_DIR}/${ARCHIVE_PATH}"

if [[ -z "${SIGN_IDENTITY}" ]]; then
  echo "SIGN_IDENTITY is required (for example: Developer ID Application: Your Name (TEAMID))."
  exit 1
fi

if [[ ! -d "${ABS_APP_PATH}" ]]; then
  echo "App bundle not found at ${ABS_APP_PATH}. Run scripts/build-app.sh first."
  exit 1
fi

echo "Signing app bundle with identity:"
echo "  ${SIGN_IDENTITY}"
codesign --force --deep --options runtime --timestamp --sign "${SIGN_IDENTITY}" "${ABS_APP_PATH}"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${ABS_APP_PATH}"
spctl --assess --type execute --verbose "${ABS_APP_PATH}"

echo "Creating zip archive for notarization..."
mkdir -p "$(dirname "${ABS_ARCHIVE_PATH}")"
rm -f "${ABS_ARCHIVE_PATH}"
ditto -c -k --keepParent "${ABS_APP_PATH}" "${ABS_ARCHIVE_PATH}"

if [[ -n "${NOTARY_PROFILE}" ]]; then
  echo "Submitting archive to Apple notarization service..."
  xcrun notarytool submit "${ABS_ARCHIVE_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
elif [[ -n "${TEAM_ID}" && -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
  echo "Submitting archive to Apple notarization service with Apple ID credentials..."
  xcrun notarytool submit "${ABS_ARCHIVE_PATH}" \
    --apple-id "${APPLE_ID}" \
    --password "${APPLE_APP_PASSWORD}" \
    --team-id "${TEAM_ID}" \
    --wait
else
  cat <<EOF
Skipping notarization because credentials were not provided.
Provide either:
  - NOTARY_PROFILE (recommended, created with notarytool store-credentials), or
  - APPLE_ID + APPLE_APP_PASSWORD + TEAM_ID
EOF
  exit 0
fi

echo "Stapling notarization ticket to app bundle..."
xcrun stapler staple "${ABS_APP_PATH}"

echo "Rebuilding zip to include stapled app..."
rm -f "${ABS_ARCHIVE_PATH}"
ditto -c -k --keepParent "${ABS_APP_PATH}" "${ABS_ARCHIVE_PATH}"

echo "Notarization flow complete:"
echo "  App: ${ABS_APP_PATH}"
echo "  Archive: ${ABS_ARCHIVE_PATH}"
