import Foundation

final class YesterdayMissedRule: MessageRule {
    let priority = 300

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else {
            return false
        }
        let isMissed = yesterday.baseStatus == .missed
        // consecutiveMissedDays 조건 제거 - 어제만 놓쳤으면 됨
        return isMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.baseStatus == .takenDouble {
            return .missedYesterdayTwoPillsDoneLate
        }

        if todayStatus.isTaken && todayStatus.baseStatus != .takenDouble {
            return .missedYesterdayNeedOneMore
        }

        if !todayStatus.isTaken {
            return .doubleDoseDoneToday
        }

        return nil
    }
}
