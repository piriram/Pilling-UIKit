import Foundation
import RxSwift

protocol UpdateScheduledTimeUseCaseProtocol {
    func execute(newTime: Date) -> Observable<Void>
}

final class UpdateScheduledTimeUseCase: UpdateScheduledTimeUseCaseProtocol {

    private let cycleRepository: CycleRepositoryProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol

    init(
        cycleRepository: CycleRepositoryProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.userDefaultsManager = userDefaultsManager
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

                return self.cycleRepository.updateScheduledTimes(
                    in: cycle.id,
                    newTimeString: newTimeString
                )
            }
    }
}
