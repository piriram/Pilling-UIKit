import Foundation

protocol MessageRule {
    var priority: Int { get }
    func evaluate(context: MessageContext) -> MessageType?
    func shouldEvaluate(context: MessageContext) -> Bool
}
