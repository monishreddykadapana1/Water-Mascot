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

When running from `swift run`, the app shows the mascot window but skips native macOS notifications because it is not yet packaged as a signed `.app` bundle.

To test quickly, click the water drop menu bar icon and choose `Test Reminder in 10 Seconds`.

## Mascot asset

The app currently looks for these mascot states:

```text
Sources/WaterMascot/Resources/Mascot/mascot_reminder.png
Sources/WaterMascot/Resources/Mascot/mascot_celebrate.png
```

## Test

```zsh
swift test
```
