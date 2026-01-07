import Foundation
import RxSwift

protocol MedicationRepositoryProtocol {
    func fetchContraceptivePills() -> Observable<[MedicationInfo]>
    func searchMedication(keyword: String) -> Observable<[MedicationInfo]>
    func refreshCache() -> Observable<Void>
    func getHardcodedPills() -> [MedicationInfo]
}
