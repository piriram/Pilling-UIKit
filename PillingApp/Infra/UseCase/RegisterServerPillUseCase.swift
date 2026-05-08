import Foundation
import RxSwift

protocol RegisterServerPillUseCaseProtocol {
    func execute(userID: String, name: String, scheduledTime: String) -> Observable<String>
}

final class RegisterServerPillUseCase: RegisterServerPillUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String, name: String, scheduledTime: String) -> Observable<String> {
        serverRepository.registerPill(userID: userID, name: name, scheduledTime: scheduledTime)
    }
}
