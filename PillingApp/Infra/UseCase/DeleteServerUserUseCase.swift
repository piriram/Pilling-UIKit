import Foundation
import RxSwift

protocol DeleteServerUserUseCaseProtocol {
    func execute(userID: String) -> Observable<Void>
}

final class DeleteServerUserUseCase: DeleteServerUserUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String) -> Observable<Void> {
        serverRepository.deleteUser(userID: userID)
    }
}
