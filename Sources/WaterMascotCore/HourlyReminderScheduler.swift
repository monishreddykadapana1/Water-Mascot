import Foundation

public struct ActiveHours {
    public var startHour: Int
    public var endHour: Int

    public static let standard = ActiveHours(startHour: 9, endHour: 21)

    public init(startHour: Int, endHour: Int) {
        self.startHour = startHour
        self.endHour = endHour
    }
}

public struct HourlyReminderScheduler {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func nextWholeHour(after date: Date, within activeHours: ActiveHours) -> Date {
        let nextHour = nextClockHour(after: date)

        if isWithinActiveHours(nextHour, activeHours: activeHours) {
            return nextHour
        }

        return nextStartOfActiveHours(after: date, activeHours: activeHours)
    }

    public func nextClockHour(after date: Date) -> Date {
        let nextHour = calendar.nextDate(
            after: date,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(3600)

        return nextHour
    }

    public func isWithinActiveHours(_ date: Date, activeHours: ActiveHours) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= activeHours.startHour && hour <= activeHours.endHour
    }

    public func nextRetry(
        after date: Date,
        before nextHourlyReminder: Date,
        interval: TimeInterval,
        cutoffBeforeNextHour: TimeInterval
    ) -> Date? {
        guard interval > 0 else {
            return nil
        }

        guard
            let currentHour = calendar.dateInterval(of: .hour, for: date)?.start,
            let nextRetryDate = nextIntervalBoundary(after: date, from: currentHour, interval: interval)
        else {
            return nil
        }

        let latestAllowedRetry = nextHourlyReminder.addingTimeInterval(-cutoffBeforeNextHour)

        guard nextRetryDate <= latestAllowedRetry else {
            return nil
        }

        return nextRetryDate
    }

    private func nextIntervalBoundary(after date: Date, from startDate: Date, interval: TimeInterval) -> Date? {
        let elapsed = date.timeIntervalSince(startDate)
        let completedIntervals = floor(elapsed / interval)
        let nextInterval = completedIntervals + 1
        return Date(timeInterval: nextInterval * interval, since: startDate)
    }

    private func nextStartOfActiveHours(after date: Date, activeHours: ActiveHours) -> Date {
        let hour = calendar.component(.hour, from: date)

        if hour < activeHours.startHour {
            return calendar.date(
                bySettingHour: activeHours.startHour,
                minute: 0,
                second: 0,
                of: date
            ) ?? date
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        return calendar.date(
            bySettingHour: activeHours.startHour,
            minute: 0,
            second: 0,
            of: tomorrow
        ) ?? tomorrow
    }
}
