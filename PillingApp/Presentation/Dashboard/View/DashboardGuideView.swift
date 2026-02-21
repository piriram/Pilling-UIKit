import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DashboardGuideView: UIView {
    // MARK: - Constants
    private let commonHorizontalInset: CGFloat = 30
    private typealias str = AppStrings.Dashboard
    // Public
    var onConfirm: (() -> Void)?
    
    // MARK: - UI
    private let dimmedBackgroundView = UIView()
    private let floatingCardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let guideStackView = UIStackView()
    private let separatorView = UIView()
    private let confirmButton = UIButton(type: .system)
    
    // MARK: - Rx
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public API
    func show(in container: UIView) {
        container.addSubview(self)
        self.snp.makeConstraints { $0.edges.equalToSuperview() }
        layoutIfNeeded()
        
        dimmedBackgroundView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.dimmedBackgroundView.alpha = 1
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmedBackgroundView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear
        
        dimmedBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        floatingCardView.backgroundColor = .systemBackground
        floatingCardView.layer.cornerRadius = 30
        floatingCardView.layer.masksToBounds = true
        
        titleLabel.text = str.guideTitle
        titleLabel.font = Typography.body1(.bold)
        titleLabel.textColor = AppColor.textBlack
        
        subtitleLabel.text = str.guideSubtitle
        subtitleLabel.font = Typography.body2(.regular)
        subtitleLabel.textColor = AppColor.secondary
        
        guideStackView.axis = .vertical
        guideStackView.spacing = 16
        guideStackView.alignment = .leading
        
        let guideItem1 = makeGuideItemWithCalendarCell(status: .taken, text: str.guideTaken)
        let guideItem2 = makeGuideItemWithCalendarCell(status: .takenDouble, text: str.guideTakenDouble)
        let guideItem3 = makeGuideItemWithCalendarCell(status: .missed, text: str.guideMissed)
        let guideItem4 = makeGuideItemWithCalendarCell(status: .notTaken, text: str.guideToday)
        
        [guideItem1, guideItem2, guideItem3, guideItem4].forEach { guideStackView.addArrangedSubview($0) }
        
        confirmButton.setTitle(str.guideConfirmButton, for: .normal)
        confirmButton.setTitleColor(AppColor.secondary, for: .normal)
        confirmButton.backgroundColor = .clear
        confirmButton.layer.cornerRadius = 12
        confirmButton.titleLabel?.font = Typography.body2(.regular)
        
        separatorView.backgroundColor = AppColor.borderGray
        
        addSubview(dimmedBackgroundView)
        addSubview(floatingCardView)
        floatingCardView.addSubview(titleLabel)
        floatingCardView.addSubview(subtitleLabel)
        floatingCardView.addSubview(guideStackView)
        floatingCardView.addSubview(separatorView)
        floatingCardView.addSubview(confirmButton)
    }
    
    private func setupConstraints() {
        dimmedBackgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        floatingCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(dimmedBackgroundView.snp.width).multipliedBy(1.1)
            make.width.equalToSuperview().inset(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().inset(commonHorizontalInset)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(commonHorizontalInset)
        }
        guideStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(commonHorizontalInset)
        }
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(commonHorizontalInset)
            make.bottom.equalTo(confirmButton.snp.top).offset(-24)
            make.height.equalTo(1)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(20)
        }
    }
    
    private func setupActions() {
        confirmButton.rx.tap
            .bind { [weak self] in
                self?.onConfirm?()
            }
            .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        dimmedBackgroundView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .bind { [weak self] _ in
                self?.onConfirm?()
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    private func makeGuideItemWithCalendarCell(status: PillStatus, text: String) -> UIView {
        let containerView = UIView()

        let calendarCell = DashboardCalendarCell()

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = Typography.body2(.regular)
        textLabel.textColor = AppColor.textBlack

        containerView.addSubview(calendarCell)
        containerView.addSubview(textLabel)

        calendarCell.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(calendarCell.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        containerView.layoutIfNeeded()

        let itemDate = status == .notTaken ? Date() : Date().addingTimeInterval(-86400)
        let dummyItem = DayItem(
            cycleDay: 1,
            date: itemDate,
            status: status,
            scheduledDateTime: Date()
        )
        calendarCell.configure(with: dummyItem)

        return containerView
    }
}
