import Foundation
import RxSwift

// MARK: - PillCycleRepositoryProtocol

protocol CycleRepositoryProtocol {
    func fetchCurrentCycle() -> Observable<Cycle?>
    func saveCycle(_ cycle: Cycle) -> Observable<Void>
    func updateRecord(_ record: DayRecord, in cycleID: UUID) -> Observable<Void>
    func updateScheduledTimes(in cycleID: UUID, newTimeString: String) -> Observable<Void>
    func deleteAllCycles() -> Observable<Void>
    func fetchCycle(by id: UUID) -> Observable<Cycle?>
}
