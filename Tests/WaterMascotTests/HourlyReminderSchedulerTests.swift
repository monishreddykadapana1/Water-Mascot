import Foundation
import XCTest
@testable import WaterMascotCore

final class HourlyReminderSchedulerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSchedulesNextWholeHourDuringActiveHours() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 9, minute: 24)))

        let next = scheduler.nextWholeHour(after: date, within: ActiveHours(startHour: 9, endHour: 21))

        XCTAssertEqual(calendar.component(.hour, from: next), 10)
        XCTAssertEqual(calendar.component(.minute, from: next), 0)
    }

    func testSkipsToNextMorningAfterActiveHours() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 22, minute: 12)))

        let next = scheduler.nextWholeHour(after: date, within: ActiveHours(startHour: 9, endHour: 21))

        XCTAssertEqual(calendar.component(.day, from: next), 4)
        XCTAssertEqual(calendar.component(.hour, from: next), 9)
        XCTAssertEqual(calendar.component(.minute, from: next), 0)
    }

    func testStartsTodayWhenBeforeActiveHours() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 7, minute: 30)))

        let next = scheduler.nextWholeHour(after: date, within: ActiveHours(startHour: 9, endHour: 21))

        XCTAssertEqual(calendar.component(.day, from: next), 3)
        XCTAssertEqual(calendar.component(.hour, from: next), 9)
        XCTAssertEqual(calendar.component(.minute, from: next), 0)
    }

    func testNextRetrySnapsToNextTenMinuteBoundary() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 10, minute: 1)))
        let nextHour = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 11, minute: 0)))

        let retry = try XCTUnwrap(scheduler.nextRetry(
            after: date,
            before: nextHour,
            interval: 10 * 60,
            cutoffBeforeNextHour: 20 * 60
        ))

        XCTAssertEqual(calendar.component(.hour, from: retry), 10)
        XCTAssertEqual(calendar.component(.minute, from: retry), 10)
    }

    func testNextRetryAllowsTwentyMinutesBeforeNextHour() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 10, minute: 35)))
        let nextHour = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 11, minute: 0)))

        let retry = try XCTUnwrap(scheduler.nextRetry(
            after: date,
            before: nextHour,
            interval: 10 * 60,
            cutoffBeforeNextHour: 20 * 60
        ))

        XCTAssertEqual(calendar.component(.hour, from: retry), 10)
        XCTAssertEqual(calendar.component(.minute, from: retry), 40)
    }

    func testNextRetryStopsInsideTwentyMinuteCutoff() throws {
        let scheduler = HourlyReminderScheduler(calendar: calendar)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 10, minute: 40)))
        let nextHour = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 11, minute: 0)))

        let retry = scheduler.nextRetry(
            after: date,
            before: nextHour,
            interval: 10 * 60,
            cutoffBeforeNextHour: 20 * 60
        )

        XCTAssertNil(retry)
    }
}
