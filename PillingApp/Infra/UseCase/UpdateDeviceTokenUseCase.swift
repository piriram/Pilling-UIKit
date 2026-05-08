import Foundation
import RxSwift

protocol UpdateDeviceTokenUseCaseProtocol {
    func execute(userID: String, deviceToken: String) -> Observable<Void>
}

final class UpdateDeviceTokenUseCase: UpdateDeviceTokenUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(userID: String, deviceToken: String) -> Observable<Void> {
        serverRepository.updateDeviceToken(userID: userID, deviceToken: deviceToken)
    }
}
