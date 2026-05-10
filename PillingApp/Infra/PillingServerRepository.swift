import Foundation
import RxSwift

final class PillingServerRepository: PillingServerRepositoryProtocol {

    private let apiService: PillingServerAPIServiceProtocol

    init(apiService: PillingServerAPIServiceProtocol) {
        self.apiService = apiService
    }

    func registerUser(userID: String, deviceToken: String) -> Observable<Void> {
        let body = RegisterUserRequest(user_id: userID, device_token: deviceToken)
        return apiService
            .post(path: "/users", body: body, responseType: UserResponse.self)
            .map { _ in }
    }

    func updateDeviceToken(userID: String, deviceToken: String) -> Observable<Void> {
        let body = UpdateDeviceTokenRequest(device_token: deviceToken)
        return apiService
            .patch(path: "/users/\(userID)/device-token", body: body, responseType: UserResponse.self)
            .map { _ in }
    }

    func deleteUser(userID: String) -> Observable<Void> {
        apiService
            .delete(path: "/users/\(userID)", responseType: UserResponse.self)
            .map { _ in }
    }

    func registerPill(userID: String, name: String, scheduledTime: String) -> Observable<String> {
        let body = RegisterPillRequest(name: name, scheduled_time: scheduledTime)
        return apiService
            .post(path: "/users/\(userID)/pills", body: body, responseType: RegisterPillResponse.self)
            .map { $0.pill_id }
    }

    func fetchPills(userID: String) -> Observable<[ServerPill]> {
        apiService
            .get(path: "/users/\(userID)/pills", responseType: [ServerPillDTO].self)
            .map { $0.map { $0.toDomain() } }
    }

    func recordPillTaken(pillID: String) -> Observable<PillTakenRecord> {
        apiService
            .post(path: "/pills/\(pillID)/taken", body: Optional<String>.none, responseType: PillTakenResponse.self)
            .map { $0.toDomain() }
    }

    func sendHeartbeat(userID: String) -> Observable<Void> {
        apiService
            .post(path: "/users/\(userID)/heartbeat", body: Optional<String>.none, responseType: UserResponse.self)
            .map { _ in }
    }
}
