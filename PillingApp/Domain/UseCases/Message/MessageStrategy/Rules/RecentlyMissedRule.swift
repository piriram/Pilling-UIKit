import Foundation

final class RecentlyMissedRule: MessageRule {
    let priority = 150

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isRecentlyMissed = context.yesterdayStatus?.baseStatus == .recentlyMissed
        return isRecentlyMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        if !context.todayIsTaken {
            return .doubleDoseComplete
        }

        return nil
    }
}
