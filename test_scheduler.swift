import Foundation

struct ActiveHours {
    var startHour: Int
    var endHour: Int
    static let standard = ActiveHours(startHour: 9, endHour: 21)
}

struct HourlyReminderScheduler {
    let calendar = Calendar.current
    func nextWholeHour(after date: Date, within activeHours: ActiveHours) -> Date {
        let nextHour = calendar.nextDate(after: date, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime) ?? date.addingTimeInterval(3600)
        let hour = calendar.component(.hour, from: nextHour)
        if hour >= activeHours.startHour && hour <= activeHours.endHour { return nextHour }
        
        if hour < activeHours.startHour {
            return calendar.date(bySettingHour: activeHours.startHour, minute: 0, second: 0, of: nextHour) ?? nextHour
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: nextHour) ?? nextHour
        return calendar.date(bySettingHour: activeHours.startHour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

let date = Date()
let scheduler = HourlyReminderScheduler()
let nextDate = scheduler.nextWholeHour(after: date, within: .standard)
print("Now: \(date)")
print("Next: \(nextDate)")
