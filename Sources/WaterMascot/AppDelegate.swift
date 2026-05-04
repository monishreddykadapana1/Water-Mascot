import AppKit
import SwiftUI
import WaterMascotCore
import WaterMascotUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = ReminderSettings()
    private let scheduler = HourlyReminderScheduler()
    private let messages = HydrationMessages()
    private let notifications = SystemNotificationClient()

    private var statusItem: NSStatusItem?
    private var mascotWindow: NSWindow?
    private var celebrationWindow: NSWindow?
    private var reminderTimer: DispatchSourceTimer?
    private var testReminderTimer: Timer?
    private var celebrationTimer: Timer?
    private var autoDismissTimer: Timer?
    private var retryReminderTimer: DispatchSourceTimer?
    private var scheduledReminderDate: Date?
    private var currentCycleNextHourlyDate: Date?
    private var isReminderVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        requestNotificationPermission()
        scheduleNextHourlyCheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        reminderTimer?.cancel()
        testReminderTimer?.invalidate()
        celebrationTimer?.invalidate()
        autoDismissTimer?.invalidate()
        retryReminderTimer?.cancel()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Water Mascot")
        item.button?.imagePosition = .imageLeading
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Water Mascot", action: #selector(showManualReminder), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Test Reminder in 10 Seconds", action: #selector(scheduleTestReminder), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pause Today", action: #selector(pauseToday), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        return menu
    }

    private func requestNotificationPermission() {
        notifications.requestPermission()
    }

    private func scheduleNextHourlyCheck(now: Date = Date()) {
        reminderTimer?.cancel()

        guard settings.isEnabled else {
            return
        }

        let nextReminderDate = scheduler.nextWholeHour(after: now, within: settings.activeHours)
        scheduledReminderDate = nextReminderDate
        let interval = max(1, nextReminderDate.timeIntervalSince(now))

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler { [weak self] in
            self?.handleHourlyReminder()
        }
        timer.resume()
        reminderTimer = timer
    }

    private func handleHourlyReminder() {
        let now = Date()
        defer { scheduleNextHourlyCheck(now: now) }

        guard settings.isEnabled, scheduler.isWithinActiveHours(now, activeHours: settings.activeHours) else {
            return
        }

        guard let scheduledReminderDate, abs(now.timeIntervalSince(scheduledReminderDate)) <= settings.missedReminderGracePeriod else {
            return
        }

        currentCycleNextHourlyDate = scheduler.nextClockHour(after: now)
        showReminder(reason: .scheduled)
    }

    private func showReminder(reason: ReminderReason) {
        guard !isReminderVisible else {
            return
        }

        if currentCycleNextHourlyDate == nil {
            currentCycleNextHourlyDate = scheduler.nextClockHour(after: Date())
        }

        autoDismissTimer?.invalidate()
        isReminderVisible = true
        let message = messages.randomReminder()
        sendNotification(message: message)

        let view = MascotReminderView(
            message: message,
            reason: reason,
            onDone: { [weak self] in
                self?.endCurrentReminderCycle()
                self?.showCelebration()
            },
            onSnooze: { [weak self] in
                self?.closeMascotWindow()
                self?.scheduleRetryReminder()
            }
        )

        let window = makeFloatingMascotWindow(width: 548, height: 190)
        window.delegate = self
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        mascotWindow = window

        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: settings.autoDismissReminderSeconds, repeats: false) { [weak self] _ in
            self?.autoDismissReminder()
        }
    }

    private func sendNotification(message: String) {
        notifications.send(title: "Water break", body: message)
    }

    private func autoDismissReminder() {
        closeMascotWindow()
        scheduleRetryReminder()
    }

    private func scheduleRetryReminder(now: Date = Date()) {
        retryReminderTimer?.cancel()

        guard
            settings.isEnabled,
            let currentCycleNextHourlyDate,
            let retryDate = scheduler.nextRetry(
                after: now,
                before: currentCycleNextHourlyDate,
                interval: settings.snoozeMinutes * 60,
                cutoffBeforeNextHour: settings.retryCutoffBeforeNextHour
            )
        else {
            return
        }

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now() + max(1, retryDate.timeIntervalSince(now)))
        timer.setEventHandler { [weak self] in
            self?.showReminder(reason: .snooze)
        }
        timer.resume()
        retryReminderTimer = timer
    }

    private func showCelebration() {
        let message = messages.randomCelebration()
        notifications.send(title: "Nice sip", body: message, playSound: false)
        showCelebrationWindow(message: message)
    }

    private func showCelebrationWindow(message: String) {
        celebrationTimer?.invalidate()
        celebrationWindow?.close()

        let view = MascotCelebrationView(message: message)
        let window = makeFloatingMascotWindow(width: 488, height: 180)
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        celebrationWindow = window

        celebrationTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            self?.celebrationWindow?.close()
            self?.celebrationWindow = nil
        }
    }

    private func makeFloatingMascotWindow(width: CGFloat, height: CGFloat) -> NSWindow {
        let window = FloatingMascotWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrameOrigin(floatingWindowOrigin(width: width, height: height))
        return window
    }

    private func floatingWindowOrigin(width: CGFloat, height: CGFloat) -> NSPoint {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let trailingPadding: CGFloat = 24
        let dockPerchOffset: CGFloat = -18

        return NSPoint(
            x: visibleFrame.maxX - width - trailingPadding,
            y: visibleFrame.minY + dockPerchOffset
        )
    }

    private func closeMascotWindow() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        isReminderVisible = false
        mascotWindow?.delegate = nil
        mascotWindow?.close()
        mascotWindow = nil
    }

    private func endCurrentReminderCycle() {
        retryReminderTimer?.cancel()
        retryReminderTimer = nil
        currentCycleNextHourlyDate = nil
        closeMascotWindow()
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === mascotWindow {
            autoDismissTimer?.invalidate()
            autoDismissTimer = nil
            isReminderVisible = false
            mascotWindow = nil
        }
    }

    @objc private func showManualReminder() {
        showReminder(reason: .manual)
    }

    @objc private func scheduleTestReminder() {
        testReminderTimer?.invalidate()
        testReminderTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.showReminder(reason: .test)
        }
    }

    @objc private func pauseToday() {
        settings.isEnabled = false
        reminderTimer?.cancel()
        testReminderTimer?.invalidate()
        celebrationTimer?.invalidate()
        autoDismissTimer?.invalidate()
        retryReminderTimer?.cancel()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private final class FloatingMascotWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
