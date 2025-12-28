import UIKit
import SnapKit

final class DashboardBottomView: UIView {

    // MARK: - UI Components
    private typealias str = AppStrings.Dashboard
    let pageControl = UIPageControl()
    let takePillButton = UIButton(type: .system)
    private var tooltip: TooltipView?
    private(set) var isRestPeriod = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AppColor.pillGreen800
        pageControl.pageIndicatorTintColor = AppColor.notYetGray
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = false

        takePillButton.setTitle(str.takePillButton, for: .normal)
        takePillButton.setTitleColor(.label, for: .normal)
        takePillButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        takePillButton.backgroundColor = AppColor.pillGreen200
        takePillButton.layer.cornerRadius = 12

        addSubview(pageControl)
        addSubview(takePillButton)
    }
    
    private func setupConstraints() {
        pageControl.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(12)
        }
        
        takePillButton.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(70)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func updatePageControl(for itemCount: Int) {
        let columns = 7
        let rows = Int(ceil(Double(itemCount) / Double(columns)))
        let rowsPerPage = 4
        let numberOfPages = Int(ceil(Double(rows) / Double(rowsPerPage)))

        pageControl.numberOfPages = max(1, numberOfPages)
        pageControl.currentPage = 0
    }
    
    func updateButton(canTake: Bool, cycle: Cycle?, environment: DateEnvironment = .default) {
        guard let cycle = cycle else { return }
        
        let calendar = environment.calendar
        let now = environment.now
        
        //TODO: 에러처리
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return
        }
        
        if case .rest = todayRecord.status {
            takePillButton.setTitle(str.restPeriod, for: .normal)
            takePillButton.backgroundColor = AppColor.breakPeriodBg
            takePillButton.setTitleColor(AppColor.breakPeriodText, for: .normal)
            takePillButton.isEnabled = true
            isRestPeriod = true
        } else if todayRecord.status.isTaken {
            isRestPeriod = false
            takePillButton.setTitle(str.takePillCompleted, for: .normal)
            takePillButton.backgroundColor = AppColor.notYetGray
            takePillButton.setTitleColor(.label, for: .normal)
            takePillButton.isEnabled = false
        } else if canTake {
            takePillButton.setTitle(str.takePillButton, for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.setTitleColor(.label, for: .normal)
            takePillButton.isEnabled = true
            isRestPeriod = false
        } else {
            takePillButton.setTitle("???", for: .normal)
            takePillButton.backgroundColor = AppColor.pillGreen200
            takePillButton.setTitleColor(.label, for: .normal)
            takePillButton.isEnabled = true
            isRestPeriod = false
        }
    }

    func showRestPeriodTooltip() {
        if let existingTooltip = tooltip {
            UIView.animate(withDuration: 0.2, animations: {
                existingTooltip.alpha = 0
                existingTooltip.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                existingTooltip.removeFromSuperview()
            }
            tooltip = nil
        } else {
            let newTooltip = TooltipView(
                message: str.restPeriodTooltip,
                backgroundColor: UIColor(hexString: "D2F9AA"),
                textColor: UIColor(hexString: "303030"),
                arrowDirection: .bottom,
                arrowPosition: .center
            )
            guard let parentView = self.superview else { return }

            parentView.addSubview(newTooltip)
            newTooltip.snp.makeConstraints { make in
                make.bottom.equalTo(takePillButton.snp.top).offset(-5)
                make.centerX.equalTo(takePillButton.snp.centerX)
            }

            newTooltip.alpha = 0
            newTooltip.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            UIView.animate(withDuration: 0.2) {
                newTooltip.alpha = 1.0
                newTooltip.transform = .identity
            }

            tooltip = newTooltip
        }
    }
}

