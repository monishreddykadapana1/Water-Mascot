# Water Mascot Progress Summary

This document summarizes the changes made to the Water Mascot application to fix bugs and improve the UI layout. You can provide this summary to the AI assistant in future sessions to restore context immediately.

## 1. Background Timer Bug Fix
- **Issue**: The application previously reminded the user exactly once and then stopped. This occurred because the app used `DispatchSourceTimer`, which measures system *uptime* rather than wall-clock time. If the Mac went to sleep, the timer would pause, causing the scheduled fire time to drift. When the timer finally fired, the app rejected the reminder because it fell outside the allowed 5-minute "grace period."
- **Solution**: We replaced `DispatchSourceTimer` with standard `Timer(fire: ...)` instances in `AppDelegate.swift`. `Timer` uses absolute wall-clock time, meaning if the Mac sleeps and wakes up, the timer fires immediately upon wake, properly respecting real-world time and triggering the reminder (or intelligently skipping and scheduling the next one).

## 2. UI Layout Redesign (Vertical Stack)
- **Issue**: The original layout placed the mascot and the message bubble side-by-side horizontally.
- **Solution**: We refactored `MascotReminderView` and `MascotCelebrationView` to use a vertical layout (`VStack`).
  - The message popup now sits **above** the mascot.
  - Both elements are center-aligned.
  - The `spacing` between the message bubble and the mascot was tightened to `-8` to bring them visually closer together.

## 3. Message Bubble Tail Polish
- **Issue**: Because the layout changed from horizontal to vertical, the small "tail" of the message bubble was pointing to the left, which no longer made sense.
- **Solution**: We updated the `MessageBubblePolygonTail` shape by applying a `rotationEffect(.degrees(-95))` to make it point directly downwards. We also adjusted its `offset` so that it seamlessly connects the bottom of the message container to the top of the mascot.

## 4. Window Container Resizing
- **Issue**: The new vertical stack was taller than the old horizontal design, causing the UI to get clipped.
- **Solution**: In `AppDelegate.swift`, we updated the `makeFloatingMascotWindow` sizes for both the Reminder and Celebration views to be exactly `width: 360, height: 340`. This securely fits the new vertical structure without any visual cutoff.

## 5. Active Hours Confirmation
- **Details**: Verified that the application's default active hours (`ActiveHours.standard`) run from **9:00 AM to 9:00 PM**. The app triggers top-of-the-hour reminders exclusively during this 12-hour window and stays silent overnight.

## 6. Build Process
- **Process**: All changes were successfully verified and compiled into a fresh macOS `.app` bundle using the `./scripts/build-app.sh` script.

## 7. Local Notification Code Signing Fix
- **Issue**: The application failed to request User Notification permissions natively (`UNErrorDomain error 1`), meaning notifications were entirely broken.
- **Solution**: macOS strictly requires applications to be code-signed to receive local notification privileges. We updated `scripts/build-app.sh` to remove inappropriately placed resource bundles (which broke signing) and automatically added ad-hoc code-signing (`codesign -s - --force --deep`). The build script now also safely zips the app using `ditto`.

## 8. App Nap and Timer Precision Fixes
- **Issue**: The hourly background timers were failing to trigger notifications because macOS "App Nap" indefinitely suspended the background app, and timer coalescing delayed the exact execution time past the strict 5-minute grace period. Furthermore, macOS silently swallowed notifications when the app was frontmost.
- **Solution**: 
  - Instructed macOS to keep the background timer alive by declaring a latency-critical system activity (`ProcessInfo.processInfo.beginActivity(options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical])`).
  - Instructed the `Timer` instances to fire with zero tolerance (`timer.tolerance = 0`).
  - Increased the `missedReminderGracePeriod` from 5 minutes to 15 minutes to guarantee slightly delayed wake-ups are still delivered.
  - Implemented `UNUserNotificationCenterDelegate` to forcefully show macOS banners even if the user clicks the menu bar icon making the app "active."

## 9. Wake Grace Period and Stale Timer Fix
- **Issue**: Timers scheduled before the Mac went to sleep would fire immediately upon waking up, bypassing the 15-minute grace period meant for the hourly cycle. This caused the mascot to trigger unexpectedly when opening the laptop late into the hour.
- **Solution**: Updated `handleWake` and the internal snooze timer logic in `AppDelegate.swift` to strictly check the elapsed time since the start of the scheduled hour. If the Mac wakes up and the elapsed time exceeds the 15-minute `missedReminderGracePeriod`, any pending snoozes or late-firing timers are automatically invalidated, ensuring reminders are strictly constrained to the grace window.
