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
            let message: MessageType
            switch status.baseStatus {
            case .taken:
                message = .takenOnTime
            case .takenDelayed:
                message = .takenDelayed
            case .takenTooEarly:
                message = .takenTooEarly
            case .takenDouble:
                message = .doubleDoseComplete
            default:
                message = .takenOnTime
            }
            return message
        }

        let message: MessageType
        switch status.medicalTiming {
        case .onTime:
            message = .onTimeNotTaken
        case .slightDelay:
            message = .overTwoHours
        case .moderate:
            message = .overFourHours
        case .recent:
            message = .missedThreePlusWarning
        case .missed:
            message = .missedThreePlusWarning
        default:
            message = .onTimeNotTaken
        }
        return message
    }
}
