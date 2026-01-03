import UIKit
import SnapKit

final class StatisticsContentView: UIView {
    
    // MARK: - Callbacks
    
    var leftArrowTapped: (() -> Void)?
    var rightArrowTapped: (() -> Void)?
    var periodButtonTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Statistics.myRecordTitle
        label.font = .systemFont(ofSize: 28, weight: .bold)
        return label
    }()
    
    private lazy var periodButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .black
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        return button
    }()
    
    private let chartContainerView = ChartContainerView()
    
    private let medicineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let recordListStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.alwaysBounceVertical = false
        contentView.addSubview(headerLabel)
        contentView.addSubview(periodButton)
        contentView.addSubview(chartContainerView)
        contentView.addSubview(medicineLabel)
        contentView.addSubview(recordListStackView)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.equalToSuperview().offset(20)
        }

        periodButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerLabel)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        chartContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(220)
        }
        
        medicineLabel.snp.makeConstraints { make in
            make.top.equalTo(chartContainerView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        recordListStackView.snp.makeConstraints { make in
            make.top.equalTo(medicineLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupActions() {
        periodButton.addTarget(self, action: #selector(handlePeriodButtonTap), for: .touchUpInside)
        
        chartContainerView.leftArrowButton.addTarget(self, action: #selector(handleLeftArrowTap), for: .touchUpInside)
        chartContainerView.rightArrowButton.addTarget(self, action: #selector(handleRightArrowTap), for: .touchUpInside)
    }
    
    @objc private func handleLeftArrowTap() {
        leftArrowTapped?()
    }
    
    @objc private func handleRightArrowTap() {
        rightArrowTapped?()
    }
    
    @objc private func handlePeriodButtonTap() {
        periodButtonTapped?()
    }
    
    // MARK: - Public Methods
    
    func configure(with data: PeriodRecordDTO) {
        periodButton.setTitle("\(data.startDateShort) - \(data.endDateShort)", for: .normal)

        chartContainerView.configure(with: data)

        if data.isEmpty {
            medicineLabel.isHidden = true
            recordListStackView.isHidden = true
        } else {
            medicineLabel.isHidden = false
            recordListStackView.isHidden = false

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: "\(AppStrings.Statistics.takingPillLabel) ",
                attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .bold)]
            ))
            attributedString.append(NSAttributedString(
                string: data.medicineName,
                attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .bold)]
            ))
            medicineLabel.attributedText = attributedString

            updateRecordList(records: data.records, skippedCount: data.skippedCount, sideEffectStats: data.sideEffectStats)
        }
    }
    
    func updateArrowButtons(isLeftEnabled: Bool, isRightEnabled: Bool) {
        chartContainerView.updateArrowButtons(
            isLeftEnabled: isLeftEnabled,
            isRightEnabled: isRightEnabled
        )
    }
    
    private func updateRecordList(records: [RecordItemDTO], skippedCount: Int, sideEffectStats: [SideEffectStatDTO]) {
        recordListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in records {
            let itemView = createRecordItemView(item: item)
            recordListStackView.addArrangedSubview(itemView)
        }

        // Add side effect statistics
        for stat in sideEffectStats {
            let sideEffectView = createSideEffectItemView(stat: stat)
            recordListStackView.addArrangedSubview(sideEffectView)
        }
    }
    
    private func createRecordItemView(item: RecordItemDTO) -> UIView {
        let containerView = UIView()
        
        let percentageLabel = UILabel()
        percentageLabel.text = "\(item.percentage)%"
        percentageLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        percentageLabel.textColor = .white
        percentageLabel.textAlignment = .center
        percentageLabel.backgroundColor = UIColor(hex: item.colorHex) ?? .gray
        percentageLabel.layer.cornerRadius = 6
        percentageLabel.clipsToBounds = true
        percentageLabel.semanticContentAttribute = .forceLeftToRight
        
        let categoryLabel = UILabel()
        categoryLabel.text = item.category
        categoryLabel.font = .systemFont(ofSize: 16)
        categoryLabel.textColor = .black
        
        let daysLabel = UILabel()
        daysLabel.text = AppStrings.Statistics.dayCount(item.days)
        daysLabel.font = .systemFont(ofSize: 16)
        daysLabel.textColor = .gray
        
        containerView.addSubview(percentageLabel)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(daysLabel)
        
        percentageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.leading.equalTo(percentageLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        daysLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        return containerView
    }
    
    private func createSideEffectItemView(stat: SideEffectStatDTO) -> UIView {
        let containerView = UIView()

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
        iconImageView.tintColor = AppColor.pillGreen600
        iconImageView.contentMode = .center

        let categoryLabel = UILabel()
        categoryLabel.text = stat.tagName
        categoryLabel.font = .systemFont(ofSize: 16)
        categoryLabel.textColor = .black

        let countLabel = UILabel()
        countLabel.text = AppStrings.Statistics.sideEffectCount(stat.count)
        countLabel.font = .systemFont(ofSize: 16)
        countLabel.textColor = .gray

        containerView.addSubview(iconImageView)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(countLabel)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(32)
        }

        categoryLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        containerView.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        return containerView
    }
}
