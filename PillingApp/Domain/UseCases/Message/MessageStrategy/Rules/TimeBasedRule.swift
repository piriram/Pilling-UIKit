import Foundation

final class TimeBasedRule: MessageRule {
    let priority = 500

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let todayStatus = context.todayStatus else {
            return false
        }

        // TimeBasedRule은 기본 폴백 룰이므로 항상 평가
        return true
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let status = context.todayStatus else { return nil }

        if status.isTaken {
            switch status.baseStatus {
            case .takenDouble:
                return .doubleDoseComplete
            default:
                return .takenComplete(timing: status.medicalTiming, minutesDiff: status.delayMinutes)
            }
        }

        return .notTakenYet(timing: status.medicalTiming)
    }
}
