import Foundation

final class EarlyTakingRule: MessageRule {
    let priority = 50

    func shouldEvaluate(context: MessageContext) -> Bool {
        // takenDouble 상태는 DoubleDosingRule에서 처리하므로 제외
        let isNotDoubleStatus = context.todayStatus?.baseStatus != .takenDouble

        // 어제 missed인 경우 YesterdayMissedRule에서 처리하므로 제외
        let yesterdayNotMissed = !context.yesterdayIsMissed

        let isTooEarly = (context.todayStatus?.isTaken == true) &&
                         (context.todayStatus?.medicalTiming == .tooEarly)

        return isTooEarly && isNotDoubleStatus && yesterdayNotMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.isTaken {
            return .takenTooEarly
        } else {
            return .plantingSeed
        }
    }
}
