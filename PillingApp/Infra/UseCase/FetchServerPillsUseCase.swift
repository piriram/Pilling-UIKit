import Foundation
import RxSwift

protocol FetchServerPillsUseCaseProtocol {
    func execute(userID: String) -> Observable<[ServerPill]>
}

final class FetchServerPillsUseCase: FetchServerPillsUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String) -> Observable<[ServerPill]> {
        serverRepository.fetchPills(userID: userID)
    }
}
