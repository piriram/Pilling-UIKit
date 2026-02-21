import Foundation
import RxSwift

protocol CreateCycleUseCaseProtocol {
    func execute(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<Cycle>
}

// MARK: - pillInfo,startDate,복용 시각 문자열로 새 Cycle과 DayRecord들을 생성하고 + 유저디폴트에 사이클 ID 저장

final class CreateCycleUseCase: CreateCycleUseCaseProtocol {
    
    private let cycleRepository: CycleRepositoryProtocol
    private let timeProvider: TimeProvider
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    init(
        cycleRepository: CycleRepositoryProtocol,
        timeProvider: TimeProvider,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.timeProvider = timeProvider
        self.userDefaultsManager = userDefaultsManager
    }
    
    func execute(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<Cycle> {
        return Observable.deferred { [weak self] in
            guard let self = self else {
                return .error(CycleError.deallocated)
            }
            
            let cycle = self.createCycle(
                pillInfo: pillInfo,
                startDate: startDate,
                scheduledTime: scheduledTime
            )
            
            // 새 사이클 ID 저장
            self.userDefaultsManager.saveCurrentCycleID(cycle.id)
            
            return self.cycleRepository.saveCycle(cycle)
                .map { cycle }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCycle(
        pillInfo: PillInfo,
        startDate: Date,
        scheduledTime: String
    ) -> Cycle {
        let now = timeProvider.now
        let today = timeProvider.startOfDay(for: now)
        
        let activeDays = pillInfo.takingDays
        let breakDays = pillInfo.breakDays
        let totalDays = activeDays + breakDays
        
        var records: [DayRecord] = []
        
        for day in 1...totalDays {
            let dayOffset = day - 1
            guard let dayDate = timeProvider.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            let scheduledDateTime = combineDateAndTime(
                date: dayDate,
                timeString: scheduledTime
            )
            
            let dayDateStartOfDay = timeProvider.startOfDay(for: dayDate)
            
            let status: PillStatus
            if day > activeDays {
                status = .rest
            } else if dayDateStartOfDay > today {
                status = .scheduled
            } else if dayDateStartOfDay == today {
                status = .notTaken
            } else {
                status = .taken
            }
            
            let takenAt: Date? = (status == .taken) ? scheduledDateTime : nil
            
            let record = DayRecord(
                id: UUID(),
                cycleDay: day,
                status: status,
                scheduledDateTime: scheduledDateTime,
                takenAt: takenAt,
                memo: "",
                createdAt: now,
                updatedAt: now
            )
            records.append(record)
        }
        
        return Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: scheduledTime,
            records: records,
            createdAt: now
        )
    }
    
    private func combineDateAndTime(date: Date, timeString: String) -> Date {
        let calendar = timeProvider.calendar
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = timeProvider.timeZone
        
        guard let timeDate = timeFormatter.date(from: timeString) else {
            return date
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.timeZone = timeProvider.timeZone
        
        return calendar.date(from: combined) ?? date
    }
}
