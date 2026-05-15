import Foundation

final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}

    private var mfdsAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "MFDS_API_KEY") as? String ?? ""
    }

    private var pillingAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "PILLING_API_KEY") as? String ?? ""
    }
    
    // MARK: - DataSources
    
    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()
    
    // MARK: - Time Provider

    lazy var timeProvider: TimeProvider = {
        SystemTimeProvider()
    }()

    // MARK: - Factories

    private lazy var pillStatusFactory: PillStatusFactory = {
        PillStatusFactory(timeProvider: timeProvider)
    }()
    
    // MARK: - Managers(싱글톤)
    
    private lazy var userDefaultsManager: UserDefaultsManagerProtocol = {
        return UserDefaultsManager()
    }()
    
    private lazy var notificationManager: NotificationManagerProtocol = {
        return LocalNotificationManager()
    }()

    // MARK: - Analytics

    private lazy var analyticsService: AnalyticsServiceProtocol = {
        #if DEBUG
        return ConsoleAnalyticsService()  // 개발 환경: 콘솔 출력
        #else
        return FirebaseAnalyticsService()  // 프로덕션: Firebase (설치 후 활성화)
        #endif
    }()

    private lazy var crashlyticsService: CrashlyticsServiceProtocol = {
        #if DEBUG
        return ConsoleCrashlyticsService()
        #else
        return FirebaseCrashlyticsService()
        #endif
    }()

    // MARK: - Repositories (싱글톤)
    
    private lazy var cycleRepository: CycleRepositoryProtocol = {
        return CycleRepository(coreDataManager: coreDataManager)
    }()
    
    private lazy var settingsRepository: UserDefaultsProtocol = {
        return UserDefaultsRepository()
    }()

    private lazy var cycleHistoryRepository: CycleHistoryProtocol = {
        return CycleHistoryRepository(context: coreDataManager.viewContext)
    }()

    private lazy var medicationRepository: MedicationRepositoryProtocol = {
        let apiService = MedicationAPIService(apiKey: mfdsAPIKey)
        return MedicationRepository(apiService: apiService)
    }()

    private lazy var medicationDetailAPIService: MedicationDetailAPIServiceProtocol = {
        return MedicationDetailAPIService(apiKey: mfdsAPIKey)
    }()

    private lazy var pillingServerAPIService: PillingServerAPIServiceProtocol = {
        return PillingServerAPIService(apiKey: pillingAPIKey)
    }()

    private lazy var pillingServerRepository: PillingServerRepositoryProtocol = {
        return PillingServerRepository(apiService: pillingServerAPIService)
    }()

    // MARK: - UseCases
    
    func makeFetchDashboardDataUseCase() -> FetchDashboardDataUseCaseProtocol {
        return FetchDashboardDataUseCase(
            cycleRepository: cycleRepository,
            settingsRepository: settingsRepository,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    func makeTakePillUseCase() -> TakePillUseCaseProtocol {
        return TakePillUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider,
            analytics: analyticsService
        )
    }
    
    func makeUpdatePillStatusUseCase() -> UpdatePillStatusUseCaseProtocol {
        return UpdatePillStatusUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider
        )
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase(
            statusFactory: pillStatusFactory,
            timeProvider: timeProvider
        )
    }
    
    func makeCreatePillCycleUseCase() -> CreateCycleUseCaseProtocol {
        return CreateCycleUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider,
            userDefaultsManager: userDefaultsManager
        )
    }

    func makeFetchStatisticsDataUseCase() -> FetchStatisticsDataUseCaseProtocol {
        return FetchStatisticsDataUseCase(
            cycleHistoryRepository: cycleHistoryRepository,
            userDefaultsManager: userDefaultsManager
        )
    }

    // MARK: - ViewModels
    
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            updatePillStatusUseCase: makeUpdatePillStatusUseCase(),
            calculateDashboardMessageUseCase: makeCalculateDashboardMessageUseCase(),
            userDefaultsManager: userDefaultsManager,
            settingsRepository: settingsRepository,
            notificationManager: notificationManager,
            analytics: analyticsService,
            recordServerPillTakenUseCase: makeRecordServerPillTakenUseCase()
        )
    }
    
    func makePillSettingViewModel() -> PillSettingViewModel {
        return PillSettingViewModel(
            userDefaultsManager: userDefaultsManager,
            detailAPIService: medicationDetailAPIService
        )
    }
    
    func makeTimeSettingViewModel() -> TimeSettingViewModel {
        return TimeSettingViewModel(
            settingsRepository: settingsRepository,
            notificationManager: notificationManager,
            userDefaultsManager: userDefaultsManager,
            createPillCycleUseCase: makeCreatePillCycleUseCase(),
            registerServerPillUseCase: makeRegisterServerPillUseCase(),
            updatePillCycleUseCase: makeUpdatePillCycleUseCase()
        )
    }
    
    func makeTimeSettingViewController() -> TimeSettingViewController {
        let viewModel = makeTimeSettingViewModel()
        return TimeSettingViewController(viewModel: viewModel)
    }
    
    func makeSettingViewModel() -> SettingViewModel {
        return SettingViewModel(
            settingsRepository: settingsRepository,
            notificationManager: notificationManager,
            pillCycleRepository: cycleRepository,
            userDefaultsManager: userDefaultsManager,
            updateScheduledTimeUseCase: makeUpdateScheduledTimeUseCase(),
            updateDeviceTokenUseCase: makeUpdateDeviceTokenUseCase(),
            updateNotificationMessageUseCase: makeUpdateNotificationMessageUseCase()
        )
    }

    func makeUpdateNotificationMessageUseCase() -> UpdateNotificationMessageUseCaseProtocol {
        UpdateNotificationMessageUseCase(serverRepository: pillingServerRepository)
    }

    func makeUpdateScheduledTimeUseCase() -> UpdateScheduledTimeUseCaseProtocol {
        return UpdateScheduledTimeUseCase(
            cycleRepository: cycleRepository,
            userDefaultsManager: userDefaultsManager,
            serverRepository: pillingServerRepository
        )
    }

    func makeSettingViewController() -> SettingViewController {
        let viewModel = makeSettingViewModel()
        return SettingViewController(viewModel: viewModel)
    }
    
    // MARK: - History
    
    func makePillCycleHistoryViewModel() -> CycleHistoryViewModel {
        return CycleHistoryViewModel(context: coreDataManager.viewContext)
    }
    
    func makeStasticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(
            fetchStatisticsDataUseCase: makeFetchStatisticsDataUseCase()
        )
    }
    
    func getPillCycleRepository() -> CycleRepositoryProtocol {
        return cycleRepository
    }
    
    func getUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return userDefaultsManager
    }

    func getMedicationRepository() -> MedicationRepositoryProtocol {
        return medicationRepository
    }

    func getAnalyticsService() -> AnalyticsServiceProtocol {
        return analyticsService
    }

    func getCrashlyticsService() -> CrashlyticsServiceProtocol {
        return crashlyticsService
    }

    func getMedicationDetailAPIService() -> MedicationDetailAPIServiceProtocol {
        return medicationDetailAPIService
    }

    // MARK: - Pilling Server Use Cases

    func makeRegisterUserUseCase() -> RegisterUserUseCaseProtocol {
        RegisterUserUseCase(serverRepository: pillingServerRepository)
    }

    func makeUpdateDeviceTokenUseCase() -> UpdateDeviceTokenUseCaseProtocol {
        UpdateDeviceTokenUseCase(serverRepository: pillingServerRepository)
    }

    func makeDeleteServerUserUseCase() -> DeleteServerUserUseCaseProtocol {
        DeleteServerUserUseCase(serverRepository: pillingServerRepository)
    }

    func makeRegisterServerPillUseCase() -> RegisterServerPillUseCaseProtocol {
        RegisterServerPillUseCase(serverRepository: pillingServerRepository)
    }

    func makeFetchServerPillsUseCase() -> FetchServerPillsUseCaseProtocol {
        FetchServerPillsUseCase(serverRepository: pillingServerRepository)
    }

    func makeRecordServerPillTakenUseCase() -> RecordServerPillTakenUseCaseProtocol {
        RecordServerPillTakenUseCase(serverRepository: pillingServerRepository)
    }

    func makeHeartbeatUseCase() -> HeartbeatUseCaseProtocol {
        HeartbeatUseCase(serverRepository: pillingServerRepository)
    }

    func makeUpdatePillCycleUseCase() -> UpdatePillCycleUseCaseProtocol {
        UpdatePillCycleUseCase(serverRepository: pillingServerRepository)
    }

    // MARK: - Test ViewControllers

    func makeMedicationDetailTestViewController() -> MedicationDetailTestViewController {
        return MedicationDetailTestViewController(detailAPIService: medicationDetailAPIService)
    }
}
