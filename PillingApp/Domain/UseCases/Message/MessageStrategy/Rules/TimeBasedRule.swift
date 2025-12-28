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
                message = .takenToday
            case .takenDelayed:
                message = .timeTakenDelayed
            case .takenTooEarly:
                message = .takenTooEarly
            case .takenDouble:
                message = .doubleDoseDoneToday
            default:
                message = .takenToday
            }
            return message
        }

        let message: MessageType
        switch status.medicalTiming {
        case .onTime:
            message = .timeOnTimeNotTaken
        case .slightDelay:
            message = .overTwoHours
        case .moderate:
            message = .overFourHours
        case .recent:
            message = .missedThreePlusDays
        case .missed:
            message = .missedThreePlusDays
        default:
            message = .timeOnTimeNotTaken
        }
        return message
    }
}
