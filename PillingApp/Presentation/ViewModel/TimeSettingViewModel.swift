import Foundation
import RxSwift
import RxCocoa

final class TimeSettingViewModel {
    
    // MARK: - Input/Output
    
    struct Input {
        let backButtonTapped: Observable<Void>
        let timeSettingButtonTapped: Observable<Void>
        let completeButtonTapped: Observable<Void>
    }
    
    struct Output {
        let showTimePicker: Driver<Void>
        let showSettingComplete: Driver<Void>
        let dismissView: Driver<Void>
        let showError: Driver<String>
    }
    
    // MARK: - Properties
    
    private let settingsRepository: UserDefaultsProtocol
    private let notificationManager: NotificationManagerProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let createPillCycleUseCase: CreateCycleUseCaseProtocol
    private let disposeBag = DisposeBag()
    
    private let selectedTime = BehaviorRelay<Date>(value: Date())
    private let isAlarmEnabled = BehaviorRelay<Bool>(value: true)
    
    // MARK: - Initialization
    
    init(
        settingsRepository: UserDefaultsProtocol,
        notificationManager: NotificationManagerProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        createPillCycleUseCase: CreateCycleUseCaseProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager
        self.userDefaultsManager = userDefaultsManager
        self.createPillCycleUseCase = createPillCycleUseCase
    }
    
    // MARK: - Transform
    
    func transform(input: Input) -> Output {
        let showTimePicker = input.timeSettingButtonTapped
            .asDriver(onErrorJustReturn: ())
        
        let errorTracker = PublishSubject<String>()
        
        let showSettingComplete = input.completeButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.completeSetup()
                    .catch { error in
                        let errorMessage = self.handleError(error)
                        errorTracker.onNext(errorMessage)
                        return .empty()
                    }
            }
            .asDriver(onErrorJustReturn: ())
        
        let dismissView = input.backButtonTapped
            .asDriver(onErrorJustReturn: ())
        
        let showError = errorTracker
            .asDriver(onErrorJustReturn: AppStrings.Error.retryLater)
        
        return Output(
            showTimePicker: showTimePicker,
            showSettingComplete: showSettingComplete,
            dismissView: dismissView,
            showError: showError
        )
    }
    
    // MARK: - Public Methods
    
    func updateTime(_ date: Date) {
        selectedTime.accept(date)
    }
    
    // MARK: - Private Methods
    
    private func completeSetup() -> Observable<Void> {
        guard let pillInfo = userDefaultsManager.loadPillInfo(),
              let startDate = userDefaultsManager.loadPillStartDate() else {
            return .error(SetupError.missingPillInfo)
        }
        
        let scheduledTimeString = selectedTime.value.formatted(style: .time24Hour)
        
        return createPillCycleUseCase.execute(
            pillInfo: pillInfo,
            startDate: startDate,
            scheduledTime: scheduledTimeString
        )
        .flatMap { [weak self] _ -> Observable<Void> in
            guard let self = self else { return .empty() }
            return self.setupNotificationAndSaveSettings()
        }
    }
    
    private func setupNotificationAndSaveSettings() -> Observable<Void> {
        // 1. 알림 권한 요청
        return notificationManager.requestAuthorization()
            .flatMap { [weak self] granted -> Observable<Void> in
                guard let self = self else { return .empty() }

                // 권한이 거부되어도 계속 진행 (알림은 선택사항)
                if granted {
                    // 2. 알림 스케줄링 (기본 메시지 사용)
                    return self.notificationManager.scheduleDailyNotification(
                        at: self.selectedTime.value,
                        isEnabled: self.isAlarmEnabled.value,
                        message: UserSettings.default.notificationMessage,
                        cycle: nil
                    )
                    .catch { _ in
                        // 알림 스케줄링 실패해도 계속 진행
                        return .just(())
                    }
                } else {
                    // 권한이 거부되면 알림 없이 계속 진행
                    return .just(())
                }
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }

                // 3. 설정 저장
                return self.saveSettings()
            }
    }
    
    private func saveSettings() -> Observable<Void> {
        return settingsRepository.fetchSettings()
            .flatMap { [weak self] currentSettings -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                let updatedSettings = UserSettings(
                    scheduledTime: self.selectedTime.value,
                    notificationEnabled: self.isAlarmEnabled.value,
                    delayThresholdMinutes: currentSettings.delayThresholdMinutes,
                    notificationMessage: UserSettings.defaultNotificationMessage
                )
                
                return self.settingsRepository.saveSettings(updatedSettings)
            }
    }
    
    private func handleError(_ error: Error) -> String {
        if let notificationError = error as? NotificationError {
            switch notificationError {
            case .permissionDenied:
                return AppStrings.Error.notificationPermissionRequired
            case .schedulingFailed:
                return AppStrings.Error.notificationSettingFailed
            case .invalidTime:
                return AppStrings.Error.invalidTime
            }
        }
        
        if let setupError = error as? SetupError {
            switch setupError {
            case .missingPillInfo:
                return AppStrings.Error.pillInfoNotFound
            }
        }
        
        return AppStrings.Error.retryLater
    }
}
