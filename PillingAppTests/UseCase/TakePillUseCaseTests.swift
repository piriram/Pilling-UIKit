import XCTest
import RxSwift
import RxBlocking
@testable import PillingApp

final class TakePillUseCaseTests: XCTestCase {
    var sut: TakePillUseCase!
    var mockTimeProvider: MockTimeProvider!
    var mockRepository: MockCycleRepository!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockTimeProvider = MockTimeProvider()
        mockRepository = MockCycleRepository()
        sut = TakePillUseCase(
            cycleRepository: mockRepository,
            timeProvider: mockTimeProvider
        )
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockTimeProvider = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - 정시 복용 테스트

    func test_정시복용_Taken_상태로_업데이트() throws {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate)

        let settings = UserSettings(
            scheduledTime: scheduledDate,
            notificationEnabled: true,
            delayThresholdMinutes: 30
        )

        // When: 09:10에 복용 (10분 늦음, 정상 범위)
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!
        mockTimeProvider.now = takenAt

        let result = try sut.execute(cycle: cycle, settings: settings, takenAt: takenAt)
            .toBlocking()
            .first()

        // Then: taken 상태로 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .taken)
        XCTAssertEqual(updatedRecord?.takenAt, takenAt)
    }

    func test_너무일찍복용_TakenTooEarly_상태로_업데이트() throws {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate)

        let settings = UserSettings(
            scheduledTime: scheduledDate,
            notificationEnabled: true,
            delayThresholdMinutes: 30
        )

        // When: 06:30에 복용 (2시간 30분 빠름)
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 6, minute: 30))!
        mockTimeProvider.now = takenAt

        let result = try sut.execute(cycle: cycle, settings: settings, takenAt: takenAt)
            .toBlocking()
            .first()

        // Then: takenTooEarly 상태로 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .takenTooEarly)
        XCTAssertEqual(updatedRecord?.takenAt, takenAt)
    }

    func test_지연복용_TakenDelayed_상태로_업데이트() throws {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate)

        let settings = UserSettings(
            scheduledTime: scheduledDate,
            notificationEnabled: true,
            delayThresholdMinutes: 30
        )

        // When: 10:00에 복용 (1시간 늦음, 임계값 초과)
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 10))!
        mockTimeProvider.now = takenAt

        let result = try sut.execute(cycle: cycle, settings: settings, takenAt: takenAt)
            .toBlocking()
            .first()

        // Then: takenDelayed 상태로 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .takenDelayed)
        XCTAssertEqual(updatedRecord?.takenAt, takenAt)
    }

    func test_이미복용한경우_업데이트하지않음() throws {
        // Given: 이미 복용한 상태
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 5))!

        let record = DayRecord(
            id: UUID(),
            cycleDay: 1,
            status: .taken,
            scheduledDateTime: scheduledDate,
            takenAt: takenAt,
            memo: "",
            createdAt: Date(),
            updatedAt: Date()
        )

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: scheduledDate,
            activeDays: 21,
            breakDays: 7,
            scheduledTime: "09:00",
            records: [record],
            createdAt: Date()
        )

        let settings = UserSettings(
            scheduledTime: scheduledDate,
            notificationEnabled: true,
            delayThresholdMinutes: 30
        )

        // When: 다시 복용 시도
        let newTakenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!
        mockTimeProvider.now = newTakenAt

        let result = try sut.execute(cycle: cycle, settings: settings, takenAt: newTakenAt)
            .toBlocking()
            .first()

        // Then: 상태 변경 없음
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .taken)
        XCTAssertEqual(updatedRecord?.takenAt, takenAt) // 원래 takenAt 유지
    }

    // MARK: - Helper Methods

    private func createTestCycle(scheduledDate: Date) -> Cycle {
        let record = DayRecord(
            id: UUID(),
            cycleDay: 1,
            status: .scheduled,
            scheduledDateTime: scheduledDate,
            takenAt: nil,
            memo: "",
            createdAt: Date(),
            updatedAt: Date()
        )

        return Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: scheduledDate,
            activeDays: 21,
            breakDays: 7,
            scheduledTime: "09:00",
            records: [record],
            createdAt: Date()
        )
    }
}

// MARK: - Mock Repository

final class MockCycleRepository: CycleRepositoryProtocol {
    var updateRecordCalled = false
    var updateRecordResult: Observable<Void> = .just(())

    func fetchCurrentCycle() -> Observable<Cycle?> {
        return .just(nil)
    }

    func saveCycle(_ cycle: Cycle) -> Observable<Void> {
        return .just(())
    }

    func updateRecord(_ record: DayRecord, in cycleID: UUID) -> Observable<Void> {
        updateRecordCalled = true
        return updateRecordResult
    }

    func deleteAllCycles() -> Observable<Void> {
        return .just(())
    }

    func fetchCycle(by id: UUID) -> Observable<Cycle?> {
        return .just(nil)
    }
}
