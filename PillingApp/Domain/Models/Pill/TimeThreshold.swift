import Foundation

enum TimeThreshold {
    static let tooEarly: TimeInterval = -2 * 60 * 60
    static let normal: TimeInterval = 2 * 60 * 60
    static let delayed: TimeInterval = 4 * 60 * 60
    static let critical: TimeInterval = 12 * 60 * 60
    static let fullyMissed: TimeInterval = 24 * 60 * 60
}
