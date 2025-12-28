import Foundation

final class MessageRuleEngine {
    private let rules: [MessageRule]

    init(rules: [MessageRule]) {
        self.rules = rules.sorted { $0.priority < $1.priority }
    }

    func evaluate(context: MessageContext) -> MessageType {
        print("🔍 [MessageRuleEngine] Starting evaluation")
        print("🔍 [MessageRuleEngine] context.todayStatus: \(String(describing: context.todayStatus))")

        for rule in rules {
            let ruleName = String(describing: type(of: rule))
            let shouldEval = rule.shouldEvaluate(context: context)

            print("🔍 [MessageRuleEngine] \(ruleName) - shouldEvaluate: \(shouldEval)")

            if shouldEval {
                if let result = rule.evaluate(context: context) {
                    print("🔍 [MessageRuleEngine] \(ruleName) returned: \(result)")
                    return result
                }
            }
        }

        print("🔍 [MessageRuleEngine] No rule matched, returning .empty")
        return .empty
    }
}
