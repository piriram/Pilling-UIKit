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
                message = .todayAfter
            case .takenDelayed:
                message = .takenDelayedOk
            case .takenTooEarly:
                message = .takenTooEarly
            case .takenDouble:
                message = .takenDoubleComplete
            default:
                message = .todayAfter
            }
            return message
        }

        let message: MessageType
        switch status.medicalTiming {
        case .onTime:
            message = .plantingSeed
        case .slightDelay:
            message = .overTwoHours
        case .moderate:
            message = .overFourHours
        case .recent:
            message = .waiting
        case .missed:
            message = .waiting
        default:
            message = .plantingSeed
        }
        return message
    }
}
