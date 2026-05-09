# Water-Mascot

A playful macOS menu bar companion that reminds you to drink water on whole-hour marks while you are using your laptop.

## Current MVP

- Native macOS menu bar app
- Whole-hour reminder scheduling
- Active hours from 9 AM to 9 PM
- Skips reminders missed while the Mac was asleep
- No stacked reminder windows
- Snooze and done actions
- Reminder and celebration mascot states
- Fixed playful reminder messages

## Run locally

```zsh
swift run WaterMascot
```

The app appears in the macOS menu bar as a water drop icon.

When running from `swift run`, the app shows the mascot window but skips native macOS notifications because it is not running as a bundled `.app`.

To test quickly, click the water drop menu bar icon and choose `Test Reminder in 10 Seconds`.

## Mascot asset

The app currently looks for these mascot states:

```text
Sources/WaterMascotUI/Resources/Mascot/mascot_reminder.png
Sources/WaterMascotUI/Resources/Mascot/mascot_celebrate.png
```

## UI preview (optional)

```zsh
swift run WaterMascotPreviewHost
```

Opens a window with the reminder and celebration layouts for quick visual checks.

## Test

```zsh
swift test
```

## Release build (signed + notarized)

The repository now includes release scripts:

- `scripts/build-app.sh`: builds a deterministic `dist/WaterMascot.app` bundle from SwiftPM.
- `scripts/sign-and-notarize.sh`: signs, verifies, notarizes, staples, and exports `dist/WaterMascot.zip`.

### 1) Build the app bundle

```zsh
scripts/build-app.sh
```

### 2) Sign and notarize (local release)

```zsh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="watermascot-notary" \
scripts/sign-and-notarize.sh
```

Alternative notarization credentials:

```zsh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_APP_PASSWORD="app-specific-password" \
TEAM_ID="TEAMID" \
scripts/sign-and-notarize.sh
```

`dist/WaterMascot.zip` is the release artifact to upload to GitHub Releases.

## GitHub Actions release pipeline

Use `.github/workflows/release.yml` to build and publish release artifacts.

### Required repository secrets

- `BUILD_CERTIFICATE_BASE64`: Base64-encoded Developer ID Application `.p12`
- `P12_PASSWORD`: password used when exporting `.p12`
- `KEYCHAIN_PASSWORD`: temporary runner keychain password
- `SIGN_IDENTITY`: `Developer ID Application: ...`
- Notarization (choose one path):
  - `NOTARY_PROFILE` (recommended keychain profile name)
  - or `APPLE_ID`, `APPLE_APP_PASSWORD`, `TEAM_ID`

### Triggers

- Push tag: `v*` (example: `v0.1.0`)
- Manual `workflow_dispatch` with version/build inputs

## Install on work laptop

1. Download `WaterMascot.zip` from the GitHub Release.
2. Unzip and move `WaterMascot.app` to `/Applications`.
3. Launch `WaterMascot.app`.
4. Grant notification permissions when prompted.
5. Confirm the menu bar icon appears and run `Test Reminder in 10 Seconds`.

## Gatekeeper troubleshooting

- If launch is blocked, verify the downloaded artifact is the signed/notarized release asset from GitHub Releases.
- If needed, re-download and ensure the file is not modified by intermediate tools.
- Security admins can validate notarization with:

```zsh
spctl --assess --type execute --verbose "/Applications/WaterMascot.app"
codesign --verify --deep --strict --verbose=2 "/Applications/WaterMascot.app"
```
