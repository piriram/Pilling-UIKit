import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - ViewController
final class StasticsViewController: UIViewController {
    
    private let viewModel: StatisticsViewModel
    private let disposeBag = DisposeBag()
    
    private let viewDidLoadSubject = PublishSubject<Void>()
    private let leftArrowTappedSubject = PublishSubject<Void>()
    private let rightArrowTappedSubject = PublishSubject<Void>()
    private let periodButtonTappedSubject = PublishSubject<Void>()
    private let dataChangedSubject = PublishSubject<Void>()
    
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
        stackView.spacing = 0
        return stackView
    }()
    
    // MARK: - Initialization
    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        bindViewModel()
        viewDidLoadSubject.onNext(())
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerLabel)
        contentView.addSubview(periodButton)
        contentView.addSubview(chartContainerView)
        contentView.addSubview(medicineLabel)
        contentView.addSubview(recordListStackView)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        periodButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerLabel)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        chartContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(250)
        }
        
        medicineLabel.snp.makeConstraints { make in
            make.top.equalTo(chartContainerView.snp.bottom).offset(60)
            make.leading.equalToSuperview().offset(20)
        }
        
        recordListStackView.snp.makeConstraints { make in
            make.top.equalTo(medicineLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func bindViewModel() {
        let input = StatisticsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            leftArrowTapped: leftArrowTappedSubject.asObservable(),
            rightArrowTapped: rightArrowTappedSubject.asObservable(),
            periodButtonTapped: periodButtonTappedSubject.asObservable(),
            dataChanged: dataChangedSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.currentPeriodData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.updateUI(with: data)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(output.isLeftArrowEnabled, output.isRightArrowEnabled)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLeftEnabled, isRightEnabled in
                self?.chartContainerView.updateArrowButtons(
                    isLeftEnabled: isLeftEnabled,
                    isRightEnabled: isRightEnabled
                )
            })
            .disposed(by: disposeBag)
        
        output.periodList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] periodList in
                self?.showPeriodSelectionAlert(periodList: periodList)
            })
            .disposed(by: disposeBag)
        
        chartContainerView.leftArrowButton.rx.tap
            .bind(to: leftArrowTappedSubject)
            .disposed(by: disposeBag)
        
        chartContainerView.rightArrowButton.rx.tap
            .bind(to: rightArrowTappedSubject)
            .disposed(by: disposeBag)
        
        periodButton.rx.tap
            .bind(to: periodButtonTappedSubject)
            .disposed(by: disposeBag)
    }
    
    private func updateUI(with data: PeriodRecordDTO) {
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
    
    private func updateRecordList(records: [RecordItemDTO], skippedCount: Int, sideEffectStats: [SideEffectStatDTO]) {

        recordListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in records {
            let itemView = createRecordItemView(item: item)
            recordListStackView.addArrangedSubview(itemView)
        }

        // Add side effect statistics
        for (index, stat) in sideEffectStats.enumerated() {
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
            make.height.equalTo(56)
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
            make.height.equalTo(56)
        }

        return containerView
    }
    
    private func showPeriodSelectionAlert(periodList: [PeriodRecordDTO]) {
        let alert = UIAlertController(title: AppStrings.Statistics.periodSelectionTitle, message: nil, preferredStyle: .actionSheet)
        
        for (index, data) in periodList.enumerated() {
            let action = UIAlertAction(title: "\(data.startDate) - \(data.endDate)", style: .default) { [weak self] _ in
                self?.viewModel.selectPeriod(at: index)
            }
            if index == viewModel.getCurrentIndex() {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel))
        
        present(alert, animated: true)
    }
}
