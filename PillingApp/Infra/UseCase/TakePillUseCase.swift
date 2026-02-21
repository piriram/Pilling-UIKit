import Foundation
import RxSwift

// MARK: - TakePillUseCaseProtocol

protocol TakePillUseCaseProtocol {
    func execute(cycle: Cycle, settings: UserSettings, takenAt: Date) -> Observable<Cycle>
}

// MARK: - 약을 복용했을 때, 복용 시간과 설정값(UserSettings)을 기준으로 복용 상태(PillStatus)를 계산하고 cycle 업데이트

final class TakePillUseCase: TakePillUseCaseProtocol {
    private let cycleRepository: CycleRepositoryProtocol
    private let timeProvider: TimeProvider
    private let analytics: AnalyticsServiceProtocol?

    init(
        cycleRepository: CycleRepositoryProtocol,
        timeProvider: TimeProvider,
        analytics: AnalyticsServiceProtocol? = nil
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
        self.analytics = analytics
    }
    
    func execute(cycle: Cycle, settings: UserSettings, takenAt: Date) -> Observable<Cycle> {
        let now = takenAt
        
        guard let todayIndex = cycle.records.firstIndex(where: {
            timeProvider.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            return .just(cycle)
        }
        
        var updatedCycle = cycle
        let record = updatedCycle.records[todayIndex]
        
        guard !record.status.isTaken else {
            return .just(cycle)
        }
        
        let timeDiff = now.timeIntervalSince(record.scheduledDateTime) // 실제 - 예정 (음수면 빠름, 양수면 늦음)
        let twoHours: TimeInterval = 2 * 60 * 60
        
        let isTooEarly = (-timeDiff) >= twoHours // 예정보다 2시간 이상 빠름
        let isWithinWindow = abs(timeDiff) <= Double(settings.delayThresholdMinutes * 60)
        
        let newStatus: PillStatus = {
            if isTooEarly {
                return .takenTooEarly
            } else if isWithinWindow {
                return .taken
            } else {
                return .takenDelayed
            }
        }()
        
        let updatedRecord = DayRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: newStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: takenAt,
            memo: record.memo,
            createdAt: record.createdAt,
            updatedAt: now
        )
        
        updatedCycle.records[todayIndex] = updatedRecord

        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .do(onNext: { [weak self] _ in
                // 성공 시에만 Analytics 이벤트 전송
                self?.analytics?.logEvent(.pillTaken(date: takenAt, status: newStatus))
            }, onError: { error in
                DIContainer.shared.getCrashlyticsService().logError(
                    error,
                    userInfo: [
                        "context": "takePill",
                        "cycleDay": record.cycleDay,
                        "takenAt": takenAt.ISO8601Format()
                    ]
                )
            })
            .map { updatedCycle }
    }
}
