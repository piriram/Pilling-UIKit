import UIKit

// MARK: - PillStatus + UIKit (본앱 전용)

extension PillStatus {

    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .takenTooEarly, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly:
            return AppColor.pillGreen800
        case .takenDouble:
            return AppColor.pillWhite
        case .missed, .recentlyMissed, .todayDelayed, .todayDelayedCritical:
            return AppColor.pillBrown
        case .scheduled, .notTaken, .todayNotTaken:
            return AppColor.notYetGray
        case .rest:
            return AppColor.pillWhite
        }
    }
}
