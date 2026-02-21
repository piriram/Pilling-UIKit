import Foundation

enum CoreDataPillStatusMapper {

    static func fromLegacyInt(_ value: Int) -> PillStatus {
        switch value {
        case 0: return .taken
        case 1: return .takenDelayed
        case 2: return .takenDouble
        case 3: return .missed
        case 8: return .scheduled
        case 9: return .rest
        case 10, 11: return .takenTooEarly
        default: return .scheduled
        }
    }

    static func toLegacyInt(_ status: PillStatus) -> Int {
        switch status {
        case .taken: return 0
        case .takenDelayed: return 1
        case .takenDouble: return 2
        case .missed: return 3
        case .scheduled: return 8
        case .rest: return 9
        case .takenTooEarly: return 10
        case .notTaken: return 8
        case .recentlyMissed: return 3
        }
    }
}
