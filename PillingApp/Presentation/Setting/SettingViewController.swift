import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class SettingViewController: UIViewController {
    
    // MARK: - Properties
    private typealias str = AppStrings.Setting
    private let viewModel: SettingViewModel
    private let analytics: AnalyticsServiceProtocol
    private let disposeBag = DisposeBag()
    private let contentInset: CGFloat = 16
    private var currentScheduledTime: Date = Date()
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let pillSectionLabel: UILabel = {
        let label = UILabel()
        label.text = str.sectionLabel
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let newPillCycleButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = AppColor.pillGreen200
        button.layer.cornerRadius = 12
        button.setTitle(str.newPillBtn, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = Typography.body1(.bold)
        return button
    }()
    
    private let alarmSectionLabel: UILabel = {
        let label = UILabel()
        label.text = str.alarmSectionTitle
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private let timeSettingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left

        let iconImageView = UIImageView(image: UIImage(systemName: "clock.fill"))
        iconImageView.tintColor = AppColor.textGray
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = str.timeSettingTitle
        titleLabel.font = Typography.body2(.medium)
        titleLabel.textColor = AppColor.textGray
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5

        let timeLabel = UILabel()
        timeLabel.tag = 100
        timeLabel.text = str.timeSettingDefault
        timeLabel.font = Typography.body2(.regular)
        timeLabel.textColor = AppColor.textBlack
        timeLabel.textAlignment = .right
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.5

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit

        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(timeLabel)
        button.addSubview(chevronImageView)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(timeLabel.snp.width).multipliedBy(0.5)
        }

        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        return button
    }()
    
    private let messageSettingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left

        let iconImageView = UIImageView(image: UIImage(systemName: "text.bubble.fill"))
        iconImageView.tintColor = AppColor.textGray
        iconImageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = str.messageSettingTitle
        titleLabel.font = Typography.body2(.medium)
        titleLabel.textColor = AppColor.textGray
        titleLabel.numberOfLines = 1
//        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        

        let messageLabel = UILabel()
        messageLabel.tag = 101
        messageLabel.text = str.messageSettingDefault
        messageLabel.font = Typography.body2(.regular)
        messageLabel.textColor = AppColor.textBlack
        messageLabel.textAlignment = .right
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.5

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit

        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        button.addSubview(messageLabel)
        button.addSubview(chevronImageView)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(messageLabel.snp.width).multipliedBy(0.5)
        }

        messageLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(8)
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: SettingViewModel, analytics: AnalyticsServiceProtocol = DIContainer.shared.getAnalyticsService()) {
        self.viewModel = viewModel
        self.analytics = analytics
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
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Configure white navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .clear
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analytics.logEvent(.screenViewed(screenName: "Settings"))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore default appearance (system background) so other screens are unaffected
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = defaultAppearance
        navigationController?.navigationBar.compactAppearance = defaultAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = defaultAppearance
        navigationController?.navigationBar.tintColor = .black
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = str.navigationTitle
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [pillSectionLabel, newPillCycleButton, alarmSectionLabel, timeSettingButton, messageSettingButton].forEach {
            contentView.addSubview($0)
        }
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        // Alarm section first
        alarmSectionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        timeSettingButton.snp.makeConstraints {
            $0.top.equalTo(alarmSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
        }

        messageSettingButton.snp.makeConstraints {
            $0.top.equalTo(timeSettingButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(68)
        }
        
        // Move pill section below alarm section
        pillSectionLabel.snp.makeConstraints {
            $0.top.equalTo(messageSettingButton.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        newPillCycleButton.snp.makeConstraints {
            $0.top.equalTo(pillSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(contentInset)
            $0.height.equalTo(60)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in }
            .asObservable()
        
        let input = SettingViewModel.Input(
            viewWillAppear: viewWillAppear,
            timeSettingTapped: timeSettingButton.rx.tap.asObservable(),
            messageSettingTapped: messageSettingButton.rx.tap.asObservable(),
            newPillCycleTapped: newPillCycleButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // 현재 설정 반영
        output.currentSettings
            .drive(onNext: { [weak self] settings in
                self?.updateUI(with: settings)
            })
            .disposed(by: disposeBag)
        
        // 시간 설정 바텀시트 표시
        output.showTimePicker
            .drive(onNext: { [weak self] in
                self?.showTimePicker()
            })
            .disposed(by: disposeBag)
        
        // 메시지 설정 Alert 표시
        output.showMessageEditor
            .drive(onNext: { [weak self] currentMessage in
                self?.showMessageEditor(currentMessage: currentMessage)
            })
            .disposed(by: disposeBag)
        
        // 새 약 복용 시작 확인
        output.showNewPillCycleConfirmation
            .drive(onNext: { [weak self] in
                self?.showNewPillCycleConfirmation()
            })
            .disposed(by: disposeBag)
        
        // 약 설정 화면으로 이동
        output.navigateToPillSetting
            .drive(onNext: { [weak self] in
                self?.navigateToPillSetting()
            })
            .disposed(by: disposeBag)
        
        // 에러 표시
        output.showError
            .drive(onNext: { [weak self] message in
                let includeSettings = message.contains("권한")
                self?.presentError(
                    title: "오류",
                    message: message,
                    includeSettingsOption: includeSettings,
                    settingsHandler: includeSettings ? {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    } : nil
                )
            })
            .disposed(by: disposeBag)
        
        // 성공 메시지 표시
        output.showSuccess
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] message in
                self?.showToast(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func updateUI(with settings: UserSettings) {
        currentScheduledTime = settings.scheduledTime
        let timeLabel = timeSettingButton.viewWithTag(100) as? UILabel
        timeLabel?.text = settings.scheduledTime.formatted(style: .timeShort)
        let messageLabel = messageSettingButton.viewWithTag(101) as? UILabel
        messageLabel?.text = settings.notificationMessage
    }
    
    private func showTimePicker() {
        let bottomSheet = TimePickerBottomSheet(initialTime: currentScheduledTime)
        
        bottomSheet.selectedTime
            .take(1)
            .flatMap { [weak self] date -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.viewModel.updateTime(date)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.showToast(message: str.messageEditorTitle)
                },
                onError: { [weak self] error in
                    self?.presentError(
                        message: str.errorTimeUpdateFailed
                    )
                }
            )
            .disposed(by: disposeBag)
        
        present(bottomSheet, animated: true)
    }
    
    private func showMessageEditor(currentMessage: String) {
        let alert = UIAlertController(
            title: str.messageEditorTitle,
            message: str.messageEditorDescription,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = currentMessage
            textField.placeholder = str.messageEditorPlaceholder
            textField.clearButtonMode = .whileEditing
        }
        
        let cancelAction = UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel)
        
        let confirmAction = UIAlertAction(title: AppStrings.Common.okBtnTitle, style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let textField = alert?.textFields?.first,
                  let newMessage = textField.text,
                  !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }

            self.analytics.logEvent(.notificationMessageChanged)
            
            self.viewModel.updateMessage(newMessage)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] in
                        self?.showToast(message: str.successMessageUpdated)
                    },
                    onError: { [weak self] error in
                        self?.presentError(
                            message: str.errorMessageUpdateFailed
                        )
                    }
                )
                .disposed(by: self.disposeBag)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    private func showNewPillCycleConfirmation() {
        let alert = UIAlertController(
            title: str.newPillCycleTitle,
            message: str.newPillCycleMessage,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel)
        
        let confirmAction = UIAlertAction(title: str.newPillCycleConfirm, style: .destructive) { [weak self] _ in
            self?.analytics.logEvent(.pillInfoEditStarted)
            self?.viewModel.startNewPillCycle()
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onError: { [weak self] error in
                        self?.presentError(
                            message: str.errorResetFailed
                        )
                    }
                )
                .disposed(by: self?.disposeBag ?? DisposeBag())
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    private func navigateToPillSetting() {
        let viewModel = DIContainer.shared.makePillSettingViewModel()
        let pillSettingVC = PillSettingViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: pillSettingVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
}
