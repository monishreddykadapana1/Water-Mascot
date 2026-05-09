import Foundation

public final class ReminderSettings {
    public var isEnabled = true
    public var activeHours = ActiveHours.standard
    public var snoozeMinutes: TimeInterval = 10
    public var autoDismissReminderSeconds: TimeInterval = 60
    public var retryCutoffBeforeNextHour: TimeInterval = 20 * 60
    public var missedReminderGracePeriod: TimeInterval = 900

    public init() {}
}
