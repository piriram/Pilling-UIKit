import Foundation

enum TimeContext: String, CaseIterable, Codable, Sendable {
    case past
    case present
    case future
}
