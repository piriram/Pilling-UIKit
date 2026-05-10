import Foundation
import RxSwift

protocol HeartbeatUseCaseProtocol {
    func execute(userID: String) -> Observable<Void>
}

final class HeartbeatUseCase: HeartbeatUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String) -> Observable<Void> {
        serverRepository.sendHeartbeat(userID: userID)
    }
}
