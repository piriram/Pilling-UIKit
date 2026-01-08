import Foundation
import RxSwift
import RxCocoa

// MARK: - DashboardViewModel

final class DashboardViewModel {

    private let fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol
    private let takePillUseCase: TakePillUseCaseProtocol
    private let updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol
    private let calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let settingsRepository: UserDefaultsProtocol
    private let notificationManager: NotificationManagerProtocol
    private let analytics: AnalyticsServiceProtocol

    private let disposeBag = DisposeBag()
    private let calendar = Calendar.current

    // MARK: - Outputs

    let settings = BehaviorRelay<UserSettings>(value: .default)
    let currentCycle = BehaviorRelay<Cycle?>(value: nil)
    let items = BehaviorRelay<[DayItem]>(value: [])
    let dashboardMessage = BehaviorRelay<DashboardMessage?>(value: nil)
    let canTakePill = BehaviorRelay<Bool>(value: false)
    let pillInfo = BehaviorRelay<PillInfo?>(value: nil)
    let showRetryAlert = PublishRelay<Void>()
    let showNewCycleAlert = PublishRelay<Void>()
    let showCompletionFloatingView = PublishRelay<Void>()
    
    // MARK: - Initialization
    
    init(
        fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol,
        takePillUseCase: TakePillUseCaseProtocol,
        updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol,
        calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        settingsRepository: UserDefaultsProtocol,
        notificationManager: NotificationManagerProtocol,
        analytics: AnalyticsServiceProtocol
    ) {
        self.fetchDashboardDataUseCase = fetchDashboardDataUseCase
        self.takePillUseCase = takePillUseCase
        self.updatePillStatusUseCase = updatePillStatusUseCase
        self.calculateDashboardMessageUseCase = calculateDashboardMessageUseCase
        self.userDefaultsManager = userDefaultsManager
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager
        self.analytics = analytics


        loadDashboardData()
        loadPillInfo()
    }
    
    // MARK: - Private Methods
    
    private func autoMarkPastScheduledAsMissed() {
        guard let cycle = currentCycle.value else { return }
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        for (index, record) in cycle.records.enumerated() {
            if record.scheduledDateTime < startOfToday {
                if case .scheduled = record.status {
                    updatePillStatusUseCase
                        .execute(
                            cycle: cycle,
                            recordIndex: index,
                            newStatus: .missed,
                            memo: nil,
                            takenAt: nil
                        )
                        .subscribe(onNext: { [weak self] updatedCycle in
                            self?.currentCycle.accept(updatedCycle)
                            self?.updateItems()
                            self?.updateDashboardMessage()
                            self?.updateCanTakePill()
                        })
                        .disposed(by: disposeBag)
                }
            }
        }
    }
    
    private func loadPillInfo() {
        if let info = userDefaultsManager.loadPillInfo() {
            pillInfo.accept(info)
        } else{
            print("pillInfo 불로오기 실패")
        }
    }
    
    private func loadDashboardData() {
        fetchDashboardDataUseCase.execute()
            .subscribe(
                onNext: { [weak self] data in
                    self?.handleSuccess(data)
                },
                onError: { [weak self] error in
                    let crashlytics = DIContainer.shared.getCrashlyticsService()
                    crashlytics.log("DashboardViewModel: loadDashboardData failed")
                    crashlytics.logError(error, userInfo: ["screen": "Dashboard"])
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func handleSuccess(_ data: (cycle: Cycle?, settings: UserSettings)) {
        self.settings.accept(data.settings)
        self.currentCycle.accept(data.cycle)

        // PillInfo가 없으면 Cycle에서 복원
        if let cycle = data.cycle, userDefaultsManager.loadPillInfo() == nil {
            let restoredPillInfo = PillInfo(
                name: "",  // 약 이름은 Cycle에 없으므로 빈 문자열
                takingDays: cycle.activeDays,
                breakDays: cycle.breakDays
            )
            userDefaultsManager.savePillInfo(restoredPillInfo)
            print("🔧 [DashboardViewModel] PillInfo를 Cycle에서 복원: takingDays=\(cycle.activeDays), breakDays=\(cycle.breakDays)")
        }

        self.updateItems()
        self.updateDashboardMessage()
        self.updateCanTakePill()
        self.autoMarkPastScheduledAsMissed()

        if let cycle = data.cycle {
            self.checkCompletionFloating(cycle)
        }
    }
    
    private func handleError(_ error: Error) {
        print("❌ 데이터 로드 실패: \(error)")
        analytics.logEvent(.dataLoadFailed(errorType: "\(error)"))
        let crashlytics = DIContainer.shared.getCrashlyticsService()
        crashlytics.log("DashboardViewModel: loadDashboardData failed")
        crashlytics.logError(error, userInfo: [
            "context": "loadDashboardData",
            "timestamp": Date().ISO8601Format()
        ])
        self.showRetryAlert.accept(())
    }
    
    private func reloadSettings() {
        settingsRepository.fetchSettings()
            .subscribe(onNext: { [weak self] settings in
                guard let self = self else { return }
                self.settings.accept(settings)
                
                if var cycle = self.currentCycle.value {
                    cycle.scheduledTime = settings.scheduledTime.formatted(style: .time24Hour)
                    self.currentCycle.accept(cycle)
                    self.updateItems()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else {
            return
        }

        let maxItems = 28
        let visibleRecords = Array(cycle.records.prefix(maxItems))
        let now = Date()
        let currentScheduledTime = settings.value.scheduledTime

        let dayItems = visibleRecords.map { record in
            var displayStatus = record.status
            let isToday = calendar.isDateInToday(record.scheduledDateTime)

            if isToday {
                let todayScheduledDateTime = calculateTodayScheduledTime(
                    from: currentScheduledTime,
                    calendar: calendar
                )

                if displayStatus != .rest {
                    if record.status == .takenDouble {
                        displayStatus = .takenDouble
                    }
                    else if !record.status.isTaken {
                        // 오늘 날짜는 늦었어도 notTaken(회색)으로 표시
                        // recentlyMissed는 과거 날짜에만 사용
                        displayStatus = .notTaken
                    }
                    else if let takenAt = record.takenAt {
                        displayStatus = calculateTakenStatus(
                            takenAt: takenAt,
                            scheduledDateTime: todayScheduledDateTime
                        )
                    }
                }
            }

            return DayItem(
                cycleDay: record.cycleDay,
                date: record.scheduledDateTime,
                status: displayStatus,
                scheduledDateTime: record.scheduledDateTime
            )
        }

        items.accept(dayItems)
    }
    
    private func calculateTodayScheduledTime(
        from scheduledTime: Date,
        calendar: Calendar
    ) -> Date {
        let now = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        var combined = DateComponents()
        combined.year = todayComponents.year
        combined.month = todayComponents.month
        combined.day = todayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? now
    }
    
    private func calculateTakenStatus(
        takenAt: Date,
        scheduledDateTime: Date
    ) -> PillStatus {
        let timeInterval = takenAt.timeIntervalSince(scheduledDateTime)
        let twoHours: TimeInterval = 2 * 60 * 60

        if timeInterval < -twoHours {
            return .takenTooEarly
        }
        else if timeInterval > twoHours {
            return .takenDelayed
        }
        else {
            return .taken
        }
    }
    
    private func updateDashboardMessage() {
        guard let cycle = currentCycle.value else {
            return
        }

        let message = calculateDashboardMessageUseCase.execute(cycle: cycle)
        debugLogCycleAndMessage(cycle: cycle, message: message)
        dashboardMessage.accept(message)
    }

    private func debugLogCycleAndMessage(cycle: Cycle, message: DashboardMessage) {
        #if DEBUG
        let dayLimit = 28
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd (EEE) HH:mm"
//
//        print("=== Dashboard Debug ===")
        print("cycleNumber=\(cycle.cycleNumber) startDate=\(dateFormatter.string(from: cycle.startDate)) activeDays=\(cycle.activeDays) breakDays=\(cycle.breakDays) scheduledTime=\(cycle.scheduledTime) totalRecords=\(cycle.records.count)")
        print("dashboardMessage=\(message.text) icon=\(message.icon.rawValue) characterImage=\(message.imageName.rawValue) background=\(message.backgroundImageName)")
        print("-- Cycle Records Statuses (first \(dayLimit) days) --")

        let sortedRecords = cycle.records.sorted { $0.scheduledDateTime < $1.scheduledDateTime }
        let statuses = sortedRecords
            .prefix(dayLimit)
            .map { $0.status.rawValue }
            .joined(separator: " | ")
        print(statuses)
        print("=== End Dashboard Debug ===")
        #endif
    }
    
    private func updateCanTakePill() {
        guard let cycle = currentCycle.value else {
            canTakePill.accept(false)
            return
        }
        
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            canTakePill.accept(false)
            return
        }
        
        if case .rest = todayRecord.status {
            canTakePill.accept(false)
            return
        }

        if todayRecord.status.isTaken {
            canTakePill.accept(false)
            return
        }

        canTakePill.accept(true)
    }
    
    // MARK: - Public Methods (Inputs)
    
    func refreshForCurrentDate() {
        guard let cycle = currentCycle.value else {
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
            return
        }

        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let hasPastScheduled = cycle.records.contains { record in
            record.scheduledDateTime < startOfToday && record.status == .scheduled
        }

        if hasPastScheduled {
            autoMarkPastScheduledAsMissed()
        } else {
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
        }

        checkCompletionFloating(cycle)
    }
    
    func reloadData() {
        loadDashboardData()
    }
    
    func refreshSettings() {
        reloadSettings()
    }
    
    func takePill() {
        guard let cycle = currentCycle.value else { return }
        let takenAt = Date()

        // Analytics: 복용하기 버튼 탭
        analytics.logEvent(.pillButtonTapped)

        takePillUseCase.execute(cycle: cycle, settings: settings.value, takenAt: takenAt)
            .subscribe(onNext: { [weak self] updatedCycle in
                guard let self = self else { return }
                self.currentCycle.accept(updatedCycle)
                self.updateItems()
                self.updateDashboardMessage()
                self.updateCanTakePill()

                // 알림 업데이트 (위약 기간 반영)
                self.updateNotificationMessage(with: updatedCycle)

                // 사이클 완료 확인
                self.checkCycleCompletion(updatedCycle)

                // 복용일 마지막 날 확인
                self.checkCompletionFloating(updatedCycle)
            })
            .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus) {
        guard let cycle = currentCycle.value else { return }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { [weak self] updatedCycle in
            self?.currentCycle.accept(updatedCycle)
            self?.updateItems()
            self?.updateDashboardMessage()
            self?.updateCanTakePill()
        })
        .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus, memo: String?, takenAt: Date? = nil) {
        print("🔍 [DashboardViewModel] updateState - index: \(index), newStatus: \(newStatus), memo: \(memo ?? "nil"), takenAt: \(String(describing: takenAt))")
        guard let cycle = currentCycle.value else {
            print("❌ updateState: cycle이 nil입니다")
            return
        }

        print("🔍 [DashboardViewModel] Calling updatePillStatusUseCase")
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: memo,
            takenAt: takenAt
        )
        .subscribe(
            onNext: { [weak self] updatedCycle in
                guard let self = self else { return }
                print("🔍 [DashboardViewModel] UseCase success - updatedCycle.records[\(index)].status: \(updatedCycle.records[index].status)")

                self.currentCycle.accept(updatedCycle)

                self.updateItems()

                self.updateDashboardMessage()

                self.updateCanTakePill()

                // 알림 업데이트 (위약 기간 반영)
                self.updateNotificationMessage(with: updatedCycle)

                // 사이클 완료 확인
                self.checkCycleCompletion(updatedCycle)

                // 복용일 마지막 날 확인
                self.checkCompletionFloating(updatedCycle)
            },
            onError: { error in
                print("❌ UseCase 에러: \(error)")
            }
        )
        .disposed(by: disposeBag)
    }

    // MARK: - Notification & Cycle Completion

    private func updateNotificationMessage(with cycle: Cycle) {
        let currentSettings = settings.value
        notificationManager.scheduleDailyNotification(
            at: currentSettings.scheduledTime,
            isEnabled: currentSettings.notificationEnabled,
            message: currentSettings.notificationMessage,
            cycle: cycle
        )
        .subscribe()
        .disposed(by: disposeBag)
    }

    private func checkCycleCompletion(_ cycle: Cycle) {
        if cycle.isCycleCompleted() {
            showNewCycleAlert.accept(())
        }
    }

    private func checkCompletionFloating(_ cycle: Cycle) {
        let now = Date()
        let totalDays = cycle.activeDays + cycle.breakDays

        let daysSinceStart = calendar.dateComponents([.day], from: cycle.startDate, to: now).day ?? 0
        let currentCycleDay = daysSinceStart + 1

        if currentCycleDay >= totalDays {
            // Analytics: 사이클 완료 플로팅뷰 표시
            analytics.logEvent(.cycleCompletionFloatingShown)
            showCompletionFloatingView.accept(())
        }
    }
}
