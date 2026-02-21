import UIKit
import SnapKit

final class CycleHistoryCell: UITableViewCell {
    static let reuseID = "CycleHistoryCell"
    
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let metaLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }
    
    private func setupUI() {
        selectionStyle = .none
        let vstack = UIStackView(arrangedSubviews: [titleLabel, subLabel, metaLabel])
        vstack.axis = .vertical
        vstack.spacing = 4
        contentView.addSubview(vstack)
        vstack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        
        // 스타일 (AppColor/Typography 있으면 사용, 없으면 시스템 폰트/색)
        titleLabel.font = Typography.headline4(.bold)
        titleLabel.textColor = AppColor.textBlack
        
        subLabel.font = Typography.body2(.medium)
        subLabel.textColor = AppColor.weekdayText
        
        metaLabel.font = Typography.caption(.regular)
        metaLabel.textColor = AppColor.weekdayText
        metaLabel.numberOfLines = 0
    }
    
    func configure(with cycle: Cycle) {
        titleLabel.text = AppStrings.History.cycleTitle(cycle.cycleNumber, totalDays: cycle.totalDays)
        let start = cycle.startDate.formatted(style: .yearMonthDayPoint)
        let created = cycle.createdAt.formatted(style: .yearMonthDayPoint)
        subLabel.text = "\(AppStrings.History.startLabel) \(start) · \(AppStrings.History.createdLabel) \(created)"
        metaLabel.text = AppStrings.History.cellMetaFormat(
            activeDays: cycle.activeDays,
            breakDays: cycle.breakDays,
            time: cycle.scheduledTime
        )
    }
}
