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

## 10. Current Package Architecture
- **Targets**:
  - `WaterMascotCore`: scheduling, settings, and message logic.
  - `WaterMascotUI`: SwiftUI mascot reminder/celebration views and mascot PNG resources.
  - `WaterMascot`: actual menu bar app executable.
  - `WaterMascotPreviewHost`: helper executable for quickly viewing the UI layout in a regular window.
- **Important files**:
  - `Sources/WaterMascot/AppDelegate.swift`: owns app lifecycle, menu bar item, timers, floating windows, and reminder flow.
  - `Sources/WaterMascot/SystemNotificationClient.swift`: wraps `UserNotifications` and foreground notification behavior.
  - `Sources/WaterMascotUI/MascotReminderView.swift`: owns the reminder bubble, mascot visuals, button styling, staged animations, and the experimental success transition.
  - `Sources/WaterMascotCore/HourlyReminderScheduler.swift`: calculates whole-hour reminders and retry boundaries.
  - `Sources/WaterMascotCore/ReminderSettings.swift`: stores default active hours and timing settings.
  - `Sources/WaterMascotCore/HydrationMessages.swift`: fixed reminder and celebration copy.

## 11. Current Reminder Behavior
- The app runs from the menu bar with a water drop icon.
- Menu options include:
  - `Show Water Mascot`
  - `Test Reminder in 10 Seconds`
  - `Pause Today`
  - `Quit`
- Reminders are scheduled on whole-hour boundaries during active hours.
- Active hours are currently `9 AM` to `9 PM`.
- If the Mac sleeps through a reminder and wakes outside the grace window, the missed reminder is skipped.
- Reminder windows do not stack.
- Reminder auto-dismisses after `60` seconds and schedules a retry if appropriate.
- Retry/snooze cadence is `10` minutes, but retries stop inside the `20` minute cutoff before the next hourly reminder.
- The mascot floating window is borderless, transparent, movable by background, and currently sized at `360 x 340`.

## 12. Current UI Design
- The UI is vertical:
  - message bubble on top
  - mascot below
- Both reminder and celebration mascot images render at `160 x 160`.
- Message bubble:
  - width `320`
  - dark fill: `Color(red: 0.15, green: 0.17, blue: 0.28)`
  - corner radius `16`
  - custom polygon tail pointing downward toward the mascot
- Reminder bubble includes:
  - message text
  - `Snooze` button
  - `On it` button
- Buttons have:
  - custom `AnimatedButtonStyle`
  - hover hand cursor
  - press scale effect from `1` to `0.97`
  - ease-out animation duration `0.15s`

## 13. Staged Mascot and Bubble Animations
- Added staged entrance animation in `MascotReminderView`.
- Entrance sequence:
  1. mascot appears first
  2. message bubble appears after `0.1s`
  3. bubble uses `easeOut` over `0.2s`
- Exit sequence for snooze:
  1. button rebounds
  2. message bubble disappears
  3. mascot disappears after `0.1s`
  4. `onSnooze` callback runs after the animation completes
- Exit sequence for success is currently experimental and handled inside `MascotReminderView`.

## 14. Experimental Success Transition
- Goal: test a smoother success flow without immediately replacing the entire reminder window.
- Current experimental flow:
  1. reminder mascot appears
  2. reminder message bubble appears
  3. user clicks `On it`
  4. reminder message bubble disappears
  5. mascot immediately switches from `mascot_reminder` to `mascot_celebrate`
  6. celebration message bubble appears after `0.1s`
  7. celebration stays visible for `3` seconds
  8. existing disappearance animation runs
  9. `onDone` callback closes the reminder cycle
- `AppDelegate.swift` now generates the celebration message before constructing `MascotReminderView` and passes it into the view.
- This is intentionally easy to revert if the interaction feels wrong. The older separate `MascotCelebrationView` still exists.

## 15. Build Artifacts and Cross-Laptop Workflow
- Current local build outputs:
  - `dist/WaterMascot.app`
  - `dist/WaterMascot.zip`
- These are build artifacts, not ideal long-term source-controlled files.
- Current practical workflow:
  1. make changes on one laptop
  2. push to GitHub
  3. download/run a build on the other laptop
  4. make changes there if needed
  5. push back and pull on the first laptop
- To automate this, we added a lightweight GitHub Actions workflow:
  - `.github/workflows/build-artifact.yml`
- It runs on:
  - pushes to `antigravity-app`
  - manual `workflow_dispatch`
- It:
  1. checks out the repo
  2. runs `scripts/build-app.sh`
  3. uploads `dist/WaterMascot.zip` as a downloadable GitHub Actions artifact
- This means the preferred install flow can become:
  1. push source code
  2. wait for GitHub Actions build
  3. download `WaterMascot.zip` from the latest workflow run on the other laptop

## 16. Release and Signing Notes
- `scripts/build-app.sh` builds an ad-hoc signed `.app` and zip locally.
- `scripts/sign-and-notarize.sh` exists for Developer ID signing and Apple notarization.
- `.github/workflows/release.yml` exists for a more formal release pipeline.
- For now, the new `build-artifact.yml` is simpler and does not require Apple Developer credentials.
- Later cleanup recommendation:
  - stop committing `dist/`
  - add `dist/` to `.gitignore`
  - use GitHub Actions artifacts for test builds
  - use GitHub Releases for stable installable versions

## 17. Current Branch and Local Change Context
- Current branch when this summary was updated:
  - `antigravity-app`
- Recently changed files include:
  - `Sources/WaterMascot/AppDelegate.swift`
  - `Sources/WaterMascotUI/MascotReminderView.swift`
  - `.github/workflows/build-artifact.yml`
  - `progress_summary.md`
- `dist/WaterMascot.app` and `dist/WaterMascot.zip` may also appear modified after local rebuilds.
