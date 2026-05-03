#!/usr/bin/env bash
set -euo pipefail

TARGET_NAME="${TARGET_NAME:-WaterMascot}"
APP_NAME="${APP_NAME:-WaterMascot}"
BUNDLE_ID="${BUNDLE_ID:-com.watermascot.app}"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-.build}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/${OUTPUT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${TARGET_NAME} in release mode..."
swift build \
  --configuration release \
  --product "${TARGET_NAME}" \
  --build-path "${DERIVED_DATA_DIR}" \
  --package-path "${ROOT_DIR}"

EXECUTABLE_PATH="${ROOT_DIR}/${DERIVED_DATA_DIR}/release/${TARGET_NAME}"
if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
  echo "Expected executable not found at ${EXECUTABLE_PATH}"
  exit 1
fi

echo "Creating app bundle at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
EOF

echo "Copying SwiftPM resource bundles..."
RESOURCE_BUNDLES_FOUND=0
for bundle_path in "${ROOT_DIR}/${DERIVED_DATA_DIR}/release/"*.bundle; do
  if [ -d "$bundle_path" ]; then
    RESOURCE_BUNDLES_FOUND=1
    # Copy to standard macOS location
    cp -R "${bundle_path}" "${RESOURCES_DIR}/"
    # Also copy to the root of the app bundle because SwiftPM's auto-generated 
    # Bundle.module expects it there when built as an executable target.
    cp -R "${bundle_path}" "${APP_DIR}/"
  fi
done

if [[ "${RESOURCE_BUNDLES_FOUND}" -eq 0 ]]; then
  echo "Warning: no .bundle resources found under ${DERIVED_DATA_DIR}/release"
fi

echo "App bundle created:"
echo "  ${APP_DIR}"
