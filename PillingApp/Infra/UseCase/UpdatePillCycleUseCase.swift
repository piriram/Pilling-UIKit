import Foundation
import RxSwift

protocol UpdatePillCycleUseCaseProtocol {
    func execute(pillID: String, cycleStartDate: Date, activeDays: Int, breakDays: Int) -> Observable<Void>
}

final class UpdatePillCycleUseCase: UpdatePillCycleUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(pillID: String, cycleStartDate: Date, activeDays: Int, breakDays: Int) -> Observable<Void> {
        serverRepository.updatePillCycle(pillID: pillID, cycleStartDate: cycleStartDate, activeDays: activeDays, breakDays: breakDays)
    }
}
