import Foundation
import RxSwift

protocol RecordServerPillTakenUseCaseProtocol {
    func execute(pillID: String) -> Observable<PillTakenRecord>
}

final class RecordServerPillTakenUseCase: RecordServerPillTakenUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(pillID: String) -> Observable<PillTakenRecord> {
        serverRepository.recordPillTaken(pillID: pillID)
    }
}
