import Foundation
import RxSwift
// MARK: - UpdatePillStatusUseCaseProtocol

protocol UpdatePillStatusUseCaseProtocol {
    func execute(
        cycle: Cycle,
        recordIndex: Int,
        newStatus: PillStatus,
        memo: String?,
        takenAt: Date?
    ) -> Observable<Cycle>
}

// MARK: - UpdatePillStatusUseCase

final class UpdatePillStatusUseCase: UpdatePillStatusUseCaseProtocol {
    private let cycleRepository: CycleRepositoryProtocol
    private let timeProvider: TimeProvider
    private let userDefaults: UserDefaults

    init(
        cycleRepository: CycleRepositoryProtocol,
        timeProvider: TimeProvider,
        userDefaults: UserDefaults = .standard
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
        self.userDefaults = userDefaults
    }
    
    func execute(
        cycle: Cycle,
        recordIndex: Int,
        newStatus: PillStatus,
        memo: String?,
        takenAt: Date? = nil
    ) -> Observable<Cycle> {

        guard cycle.records.indices.contains(recordIndex) else {
            print("   ❌ recordIndex가 범위를 벗어남")
            return .just(cycle)
        }

        var updatedCycle = cycle
        let record = updatedCycle.records[recordIndex]
        let now = timeProvider.now

        // 과거 날짜를 scheduled 또는 notTaken으로 바꾸려는 경우 자동으로 missed로 변환
        let finalStatus: PillStatus
        if newStatus == .scheduled || newStatus == .notTaken {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let isPastDate = record.scheduledDateTime < startOfToday

            if isPastDate {
                finalStatus = .missed
            } else {
                finalStatus = newStatus
            }
        } else {
            finalStatus = newStatus
        }

        // takenAt 결정 로직:
        // 1. 명시적으로 전달된 takenAt이 있으면 사용
        // 2. 없으면 기존 로직 적용 (상태가 taken이면 record.takenAt ?? now)
        let finalTakenAt: Date?
        if let providedTakenAt = takenAt {
            finalTakenAt = providedTakenAt
        } else {
            finalTakenAt = finalStatus.isTaken ? (record.takenAt ?? now) : nil
        }

        // takenAt이 명시적으로 전달되고 복용 상태일 때, 시간 기준으로 상태 재계산
        let recalculatedStatus: PillStatus
        if let actualTakenAt = finalTakenAt, finalStatus.isTaken {
            // takenDouble 상태는 시간 재계산 없이 그대로 유지
            if finalStatus == .takenDouble {
                recalculatedStatus = .takenDouble
            } else {
                let delayThresholdMinutes = userDefaults.object(forKey: "delayThresholdMinutes") as? Int ?? 120
                let timeDiff = actualTakenAt.timeIntervalSince(record.scheduledDateTime)
                let twoHours: TimeInterval = 2 * 60 * 60

                let isTooEarly = (-timeDiff) >= twoHours
                let isWithinWindow = abs(timeDiff) <= Double(delayThresholdMinutes * 60)

                if isTooEarly {
                    recalculatedStatus = .takenTooEarly
                } else if isWithinWindow {
                    recalculatedStatus = .taken
                } else {
                    recalculatedStatus = .takenDelayed
                }
            }
        } else {
            recalculatedStatus = finalStatus
        }

        let finalMemo = memo ?? record.memo
        
        let updatedRecord = DayRecord(
            id: record.id,
            cycleDay: record.cycleDay,
            status: recalculatedStatus,
            scheduledDateTime: record.scheduledDateTime,
            takenAt: finalTakenAt,
            memo: finalMemo,
            createdAt: record.createdAt,
            updatedAt: now
        )

        updatedCycle.records[recordIndex] = updatedRecord

        return cycleRepository.updateRecord(updatedRecord, in: cycle.id)
            .map { updatedCycle }
    }
}
