import Foundation
import UserNotifications

final class SystemNotificationClient {
    var canUseSystemNotifications: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    func requestPermission() {
        guard canUseSystemNotifications else {
            print("Skipping notification permission: WaterMascot is running without an app bundle identifier.")
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Notification permission granted: \(granted)")
        }
    }

    func send(title: String, body: String, playSound: Bool = true) {
        guard canUseSystemNotifications else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = playSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: "water-mascot-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
