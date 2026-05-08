import Foundation
import RxSwift

protocol RegisterUserUseCaseProtocol {
    func execute(userID: String, deviceToken: String) -> Observable<Void>
}

final class RegisterUserUseCase: RegisterUserUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String, deviceToken: String) -> Observable<Void> {
        serverRepository.registerUser(userID: userID, deviceToken: deviceToken)
    }
}
