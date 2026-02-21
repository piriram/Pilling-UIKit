import UIKit

// MARK: - PillStatus + UIKit (본앱 전용)

extension PillStatus {

    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .takenTooEarly:
            return AppColor.pillGreen800
        case .takenDouble:
            return AppColor.pillWhite
        case .missed, .recentlyMissed:
            return AppColor.pillBrown
        case .scheduled, .notTaken:
            return AppColor.notYetGray
        case .rest:
            return AppColor.pillWhite
        }
    }
}
