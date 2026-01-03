import UIKit
import SnapKit


final class DashboardCalendarCell: UICollectionViewCell {
    static let identifier = "CalendarCell"
    
    private let backgroundShapeView = UIView()
    private let innerBorderView = UIView() // inner shadow 대체용
    private let capsuleContainer = UIView()
    private let capsule1 = UIView()
    private let capsule2 = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let defaultCornerRadius = min(bounds.width, bounds.height) * 0.3
        let capsuleCornerRadius = min(bounds.width, bounds.height) * 0.25
        
        if backgroundShapeView.layer.cornerRadius != 0 {
            backgroundShapeView.layer.cornerRadius = defaultCornerRadius
            innerBorderView.layer.cornerRadius = defaultCornerRadius - 3
        }
        
        capsule1.layer.cornerRadius = capsuleCornerRadius
        capsule2.layer.cornerRadius = capsuleCornerRadius
    }
    
    private func setupViews() {
        contentView.addSubview(backgroundShapeView)
        backgroundShapeView.addSubview(innerBorderView)
        backgroundShapeView.addSubview(capsuleContainer)
        capsuleContainer.addSubview(capsule1)
        capsuleContainer.addSubview(capsule2)

        backgroundShapeView.layer.masksToBounds = true
        backgroundShapeView.snp.makeConstraints {
            $0.edges.equalToSuperview().priority(.high)
        }

        // inner shadow 효과를 내는 border view
        innerBorderView.isUserInteractionEnabled = false
        innerBorderView.backgroundColor = .clear
        innerBorderView.layer.borderWidth = 3
        innerBorderView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(3).priority(.high)
        }

        capsuleContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(backgroundShapeView.snp.width)
        }

        capsule1.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(0.5)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsuleContainer.snp.width).multipliedBy(0.5).offset(-1.5).priority(.high)
        }

        capsule2.snp.makeConstraints { make in
            make.leading.equalTo(capsule1.snp.trailing).offset(2).priority(.high)
            make.trailing.equalToSuperview().inset(0.5)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(capsule1)
        }

        capsule1.backgroundColor = AppColor.pillGreen800
        capsule2.backgroundColor = AppColor.pillGreen800

        capsuleContainer.isHidden = true
        innerBorderView.isHidden = true
        contentView.backgroundColor = .clear
    }
    
    func configure(with item: DayItem) {
        backgroundShapeView.layer.borderWidth = 0
        backgroundShapeView.layer.borderColor = UIColor.clear.cgColor
        innerBorderView.isHidden = true
        innerBorderView.layer.borderColor = UIColor.clear.cgColor
        capsuleContainer.isHidden = true
        
        backgroundShapeView.backgroundColor = item.status.backgroundColor
        
        if case .takenDouble = item.status {
            backgroundShapeView.layer.cornerRadius = 0
            innerBorderView.layer.cornerRadius = 0
        } else {
            let defaultCornerRadius = min(bounds.width, bounds.height) * 0.3
            backgroundShapeView.layer.cornerRadius = defaultCornerRadius
            innerBorderView.layer.cornerRadius = defaultCornerRadius - 3
        }
        
        if item.isToday && item.status != .takenDouble {
            backgroundShapeView.layer.borderWidth = 4
            backgroundShapeView.layer.borderColor = AppColor.pillGreen800.cgColor
        }
        
        if case .rest = item.status, !item.isToday {
            backgroundShapeView.layer.borderWidth = 1
            backgroundShapeView.layer.borderColor = AppColor.notYetGray.cgColor
        }
        
        if case .takenDouble = item.status {
            capsuleContainer.isHidden = false
        }
    }
}
