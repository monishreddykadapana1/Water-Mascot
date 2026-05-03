import SwiftUI
import WaterMascotUI

@main
struct WaterMascotPreviewHostApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 28) {
                MascotReminderView(
                    message: "Hydration timeout. One quick sip, then back in the match.",
                    reason: .test,
                    onDone: {},
                    onSnooze: {}
                )

                MascotCelebrationView(message: "Hydration point secured.")
            }
            .padding(32)
            .frame(minWidth: 620, minHeight: 520)
        }
    }
}
