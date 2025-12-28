import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class PillSettingViewController: UIViewController {
    
    // MARK: - Properties
    private typealias str = AppStrings.PillSetting
    private let viewModel: PillSettingViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "PillSetting")
        return imageView
    }()
    
    private let mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = str.mainTitle
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .left
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = str.subtitle
        label.font = Typography.body2(.regular)
        label.textColor = .gray
        label.textAlignment = .left
        return label
    }()
    
    private let pillTypeButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: str.btnTitle, iconSystemName: "pills")
        return button
    }()
    
    private let currentDaysButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: str.ctnBtnTitle, iconSystemName: "calendar")
        return button
    }()
    
    private let nextButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(str.nextBtnTitle, for: .normal)
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: PillSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureNavigationBar()
        bind()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(iconImageView)
        view.addSubview(mainTitleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(pillTypeButton)
        view.addSubview(currentDaysButton)
        view.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(0)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(200)
        }
        
        mainTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(mainTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        pillTypeButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(48)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        currentDaysButton.snp.makeConstraints {
            $0.top.equalTo(pillTypeButton.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(70)
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = ""
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = false
        navigationItem.backButtonDisplayMode = .default
    }
    
    private func bind() {
        // Input
        pillTypeButton.rx.tap
            .bind(to: viewModel.input.pillTypeButtonTapped)
            .disposed(by: disposeBag)
        
        currentDaysButton.rx.tap
            .bind(to: viewModel.input.startDateButtonTapped)
            .disposed(by: disposeBag)
        
        nextButton.rx.tap
            .bind(to: viewModel.input.nextButtonTapped)
            .disposed(by: disposeBag)
        
        // Output
        viewModel.output.selectedPillTypeText
            .drive(onNext: { [weak self] text in
                self?.pillTypeButton.setValue(text)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.selectedStartDateText
            .drive(onNext: { [weak self] dateText in
                self?.currentDaysButton.setValue(dateText)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isNextButtonEnabled
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.output.presentDatePicker
            .emit(onNext: { [weak self] in
                self?.presentDatePickerBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.presentPillTypePicker
            .emit(onNext: { [weak self] in
                self?.presentPillTypeBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.proceed
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                let vm = DIContainer.shared.makeTimeSettingViewModel()
                let nextVC = TimeSettingViewController(viewModel: vm)
                if let nav = self.navigationController {
                    nav.pushViewController(nextVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.alertMessage
            .emit(onNext: { [weak self] message in
                self?.presentNotification(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func presentDatePickerBottomSheet() {
        let datePickerVC = DatePickerBottomSheetViewController()
        
        datePickerVC.selectedDate
            .emit(to: viewModel.input.dateSelected)
            .disposed(by: disposeBag)
        
        present(datePickerVC, animated: false)
    }
    
    private func presentPillTypeBottomSheet() {
        let pillTypeVC = PillTypeBottomSheetViewController()
        
        pillTypeVC.pillInfoSelected
            .bind(to: viewModel.input.pillInfoSelected)
            .disposed(by: disposeBag)
        
        present(pillTypeVC, animated: false)
    }
}
