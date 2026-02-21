import Foundation

struct DayItem: Hashable, Sendable, Identifiable {
    let id: UUID
    let cycleDay: Int
    let date: Date
    let status: PillStatus
    let scheduledDateTime: Date

    init(
        id: UUID = UUID(),
        cycleDay: Int,
        date: Date,
        status: PillStatus,
        scheduledDateTime: Date
    ) {
        self.id = id
        self.cycleDay = cycleDay
        self.date = date
        self.status = status
        self.scheduledDateTime = scheduledDateTime
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
