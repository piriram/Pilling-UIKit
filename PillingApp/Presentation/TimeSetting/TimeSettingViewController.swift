import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class TimeSettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private typealias Str = AppStrings.TimeSetting
    private let viewModel: TimeSettingViewModel
    private let disposeBag = DisposeBag()
    private let contentInset: CGFloat = 16
    
    // MARK: - UI Components
    
    private let clockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "clock_image")
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "timeSetting")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = Str.mainTitle
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .natural
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = Str.subtitle
        label.font = Typography.body2(.regular)
        label.textColor = .gray
        label.textAlignment = .natural
        return label
    }()
    
    private let timeSettingButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: Str.timeButtonTitle, iconSystemName: "clock.fill")
        button.setValue(nil)
        return button
    }()
    
    private let completeButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(Str.confirmButton, for: .normal)
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: TimeSettingViewModel) {
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
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = .black
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = Str.navigationTitle
        navigationItem.hidesBackButton = false
        navigationItem.backButtonDisplayMode = .default
        
        [clockImageView, titleLabel, subtitleLabel,
         timeSettingButton, completeButton].forEach {
            view.addSubview($0)
        }
        
        clockImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalTo(view).inset(contentInset)
            $0.height.equalTo(200)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(clockImageView.snp.bottom).offset(32)
            $0.leading.trailing.equalTo(view).inset(contentInset)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(view).inset(contentInset)
        }
        
        timeSettingButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(52)
            $0.leading.trailing.equalTo(view).inset(contentInset)
            $0.height.equalTo(60)
        }
        
        completeButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(contentInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(70)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        let input = TimeSettingViewModel.Input(
            backButtonTapped: Observable<Void>.empty(),
            timeSettingButtonTapped: timeSettingButton.rx.tap.asObservable(),
            completeButtonTapped: completeButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.showTimePicker
            .drive(onNext: { [weak self] in
                self?.showDatePicker()
            })
            .disposed(by: disposeBag)
        
        output.showSettingComplete
            .drive(onNext: { [weak self] in
                self?.showSettingCompleteFloatingView()
            })
            .disposed(by: disposeBag)
        
        output.showError
            .drive(onNext: { [weak self] errorMessage in
                let includeSettings = errorMessage == AppStrings.Error.notificationPermissionRequired
                self?.presentError(
                    title: AppStrings.Error.notificationPermissionTitle,
                    message: errorMessage,
                    includeSettingsOption: includeSettings,
                    settingsHandler: includeSettings ? {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    } : nil
                )
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func showDatePicker() {
        let bottomSheet = TimePickerBottomSheet()
        
        bottomSheet.selectedTime
            .take(1)
            .subscribe(onNext: { [weak self] date in
                self?.viewModel.updateTime(date)
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.timeZone = TimeZone.current
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                let timeString = formatter.string(from: date)
                self?.timeSettingButton.setValue(timeString)
            })
            .disposed(by: disposeBag)
        
        present(bottomSheet, animated: true)
    }
    
    private func showSettingCompleteFloatingView() {
        let floatingView = SettingCompleteFloatingView()
        
        floatingView.onAutoDismiss = { [weak self] in
            self?.navigateToDashboard()
        }
        
        floatingView.show(in: view)
    }
    
    private func navigateToDashboard() {
        let dashboardViewModel = DIContainer.shared.makeDashboardViewModel()
        let stasticsViewModel = DIContainer.shared.makeStasticsViewModel()
        let userDefaultsManager = DIContainer.shared.getUserDefaultsManager()
        let timeProvider = DIContainer.shared.timeProvider
        let dashboardVC = DashboardViewController(
            viewModel: dashboardViewModel,
            stasticsViewModel: stasticsViewModel,
            userDefaultsManager: userDefaultsManager,
            timeProvider: timeProvider
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let navigationController = UINavigationController(rootViewController: dashboardVC)
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
}
