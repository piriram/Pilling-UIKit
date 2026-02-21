import Foundation

enum PillStatus: String, CaseIterable, Codable, Sendable {
    case taken
    case takenDelayed
    case takenTooEarly
    case takenDouble
    case notTaken
    case recentlyMissed
    case missed
    case scheduled
    case rest

    var isTaken: Bool {
        switch self {
        case .taken, .takenDelayed, .takenTooEarly, .takenDouble:
            return true
        default:
            return false
        }
    }
}
