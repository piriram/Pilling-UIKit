import Foundation

final class ConsecutiveMissedRule: MessageRule {
    let priority = 100

    func shouldEvaluate(context: MessageContext) -> Bool {
        // 2일 이상 연속 누락만 처리
        let hasMissed = context.consecutiveMissedDays >= 2
        return hasMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        let days = context.consecutiveMissedDays

        if days >= 2 {
            return .consecutiveMissedWarning(days: days)
        }

        return nil
    }
}
