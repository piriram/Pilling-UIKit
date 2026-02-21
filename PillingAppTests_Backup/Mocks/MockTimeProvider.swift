import Foundation
@testable import PillingApp

final class MockTimeProvider: TimeProvider {
    var now: Date
    var calendar: Calendar
    var timeZone: TimeZone

    init(
        now: Date = Date(),
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone.current
    ) {
        self.now = now
        self.calendar = calendar
        self.calendar.timeZone = timeZone
        self.timeZone = timeZone
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }

    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }
}
