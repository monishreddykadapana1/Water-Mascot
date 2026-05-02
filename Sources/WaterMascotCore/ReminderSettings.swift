import Foundation

public final class ReminderSettings {
    public var isEnabled = true
    public var activeHours = ActiveHours.standard
    public var snoozeMinutes: TimeInterval = 10
    public var missedReminderGracePeriod: TimeInterval = 90

    public init() {}
}
