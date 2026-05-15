import Foundation
import RxSwift

protocol UpdateScheduledTimeUseCaseProtocol {
    func execute(newTime: Date) -> Observable<Void>
}

final class UpdateScheduledTimeUseCase: UpdateScheduledTimeUseCaseProtocol {

    private let cycleRepository: CycleRepositoryProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let serverRepository: PillingServerRepositoryProtocol

    init(
        cycleRepository: CycleRepositoryProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        serverRepository: PillingServerRepositoryProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.userDefaultsManager = userDefaultsManager
        self.serverRepository = serverRepository
    }

    func execute(newTime: Date) -> Observable<Void> {
        return cycleRepository.fetchCurrentCycle()
            .flatMap { [weak self] cycle -> Observable<Void> in
                guard let self = self else { return .empty() }
                guard let cycle = cycle else { return .just(()) }

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                timeFormatter.timeZone = TimeZone.current
                let newTimeString = timeFormatter.string(from: newTime)

                let localUpdate = self.cycleRepository.updateScheduledTimes(
                    in: cycle.id,
                    newTimeString: newTimeString
                )

                guard
                    let pillID = self.userDefaultsManager.loadServerPillID()
                else {
                    return localUpdate
                }

                let serverUpdate = self.serverRepository.updatePillCycle(
                    pillID: pillID,
                    cycleStartDate: cycle.startDate,
                    activeDays: cycle.activeDays,
                    breakDays: cycle.breakDays,
                    scheduledTime: newTimeString
                ).catchAndReturn(())

                return localUpdate.flatMap { serverUpdate }
            }
    }
}
