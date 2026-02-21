import Foundation

enum MedicalTiming: String, CaseIterable, Codable, Sendable {
    case tooEarly
    case upcoming
    case onTime
    case slightDelay
    case moderate
    case recent
    case missed
}
