import Foundation

struct MessageContext {
    let todayStatus: PillStatusModel?
    let yesterdayStatus: PillStatusModel?
    let cycle: Cycle
    let currentDate: Date
    let consecutiveMissedDays: Int
    let timeProvider: TimeProvider

    var todayIsTaken: Bool {
        todayStatus?.isTaken ?? false
    }

    var yesterdayIsMissed: Bool {
        guard let yesterday = yesterdayStatus else { return false }
        return yesterday.baseStatus == .missed ||
               yesterday.baseStatus == .recentlyMissed
    }

    var canTakeDoubleToday: Bool {
        todayStatus?.canTakeDouble ?? false
    }
}
