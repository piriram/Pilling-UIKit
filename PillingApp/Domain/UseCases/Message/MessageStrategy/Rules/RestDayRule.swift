import Foundation

final class RestDayRule: MessageRule {
    let priority = 75

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isRest = context.todayStatus?.baseStatus == .rest
        return isRest
    }

    func evaluate(context: MessageContext) -> MessageType? {
        return .resting
    }
}
