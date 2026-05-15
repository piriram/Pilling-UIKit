import Foundation
import RxSwift

protocol PillingServerRepositoryProtocol {
    func registerUser(userID: String, deviceToken: String) -> Observable<Void>
    func updateDeviceToken(userID: String, deviceToken: String) -> Observable<Void>
    func deleteUser(userID: String) -> Observable<Void>
    func registerPill(userID: String, name: String, scheduledTime: String) -> Observable<String>
    func fetchPills(userID: String) -> Observable<[ServerPill]>
    func recordPillTaken(pillID: String) -> Observable<PillTakenRecord>
    func sendHeartbeat(userID: String) -> Observable<Void>
    func updatePillCycle(pillID: String, cycleStartDate: Date, activeDays: Int, breakDays: Int, scheduledTime: String?) -> Observable<Void>
    func updatePillNotificationMessage(pillID: String, message: String) -> Observable<Void>
}
