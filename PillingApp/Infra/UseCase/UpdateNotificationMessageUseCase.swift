import Foundation
import RxSwift

protocol UpdateNotificationMessageUseCaseProtocol {
    func execute(pillID: String, message: String) -> Observable<Void>
}

final class UpdateNotificationMessageUseCase: UpdateNotificationMessageUseCaseProtocol {

    private let serverRepository: PillingServerRepositoryProtocol

    init(serverRepository: PillingServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    func execute(pillID: String, message: String) -> Observable<Void> {
        serverRepository.updatePillNotificationMessage(pillID: pillID, message: message)
    }
}
