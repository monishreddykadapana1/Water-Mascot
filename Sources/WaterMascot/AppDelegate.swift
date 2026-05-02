import AppKit
import SwiftUI
import WaterMascotCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let settings = ReminderSettings()
    private let scheduler = HourlyReminderScheduler()
    private let messages = HydrationMessages()
    private let notifications = SystemNotificationClient()

    private var statusItem: NSStatusItem?
    private var mascotWindow: NSWindow?
    private var celebrationWindow: NSWindow?
    private var reminderTimer: Timer?
    private var testReminderTimer: Timer?
    private var celebrationTimer: Timer?
    private var scheduledReminderDate: Date?
    private var isReminderVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        requestNotificationPermission()
        scheduleNextHourlyCheck()
    }

    func applicationWillTerminate(_ notification: Notification) {
        reminderTimer?.invalidate()
        testReminderTimer?.invalidate()
        celebrationTimer?.invalidate()
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
        reminderTimer?.invalidate()

        guard settings.isEnabled else {
            return
        }

        let nextReminderDate = scheduler.nextWholeHour(after: now, within: settings.activeHours)
        scheduledReminderDate = nextReminderDate
        let interval = max(1, nextReminderDate.timeIntervalSince(now))

        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleHourlyReminder()
        }
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

        showReminder(reason: .scheduled)
    }

    private func showReminder(reason: ReminderReason) {
        guard !isReminderVisible else {
            return
        }

        isReminderVisible = true
        let message = messages.randomReminder()
        sendNotification(message: message)

        let view = MascotReminderView(
            message: message,
            reason: reason,
            onDone: { [weak self] in
                self?.closeMascotWindow()
                self?.showCelebration()
            },
            onSnooze: { [weak self] in
                self?.closeMascotWindow()
                self?.scheduleSnooze()
            }
        )

        let window = makeFloatingMascotWindow(width: 510, height: 190)
        window.delegate = self
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        mascotWindow = window
    }

    private func sendNotification(message: String) {
        notifications.send(title: "Water break", body: message)
    }

    private func scheduleSnooze() {
        Timer.scheduledTimer(withTimeInterval: settings.snoozeMinutes * 60, repeats: false) { [weak self] _ in
            self?.showReminder(reason: .snooze)
        }
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
        let window = makeFloatingMascotWindow(width: 420, height: 190)
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
        let padding: CGFloat = 24

        return NSPoint(
            x: visibleFrame.maxX - width - padding,
            y: visibleFrame.minY + padding
        )
    }

    private func closeMascotWindow() {
        isReminderVisible = false
        mascotWindow?.delegate = nil
        mascotWindow?.close()
        mascotWindow = nil
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === mascotWindow {
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
        reminderTimer?.invalidate()
        testReminderTimer?.invalidate()
        celebrationTimer?.invalidate()
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
