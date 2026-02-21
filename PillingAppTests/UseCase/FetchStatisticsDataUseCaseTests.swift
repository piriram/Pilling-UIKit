import XCTest
import RxSwift
import RxBlocking
@testable import PillingApp

final class FetchStatisticsDataUseCaseTests: XCTestCase {
    var sut: FetchStatisticsDataUseCase!
    var mockRepository: MockCycleHistoryRepository!
    var mockUserDefaultsManager: MockUserDefaultsManager!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockRepository = MockCycleHistoryRepository()
        mockUserDefaultsManager = MockUserDefaultsManager()
        sut = FetchStatisticsDataUseCase(
            cycleHistoryRepository: mockRepository,
            userDefaultsManager: mockUserDefaultsManager
        )
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockUserDefaultsManager = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - 복용률 계산 테스트

    func test_복용률_100퍼센트_계산() throws {
        // Given: 모든 날짜 정시 복용
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let records = [
            createRecord(scheduledDate: startDate, cycleDay: 1, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 1, to: startDate)!, cycleDay: 2, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 2, to: startDate)!, cycleDay: 3, status: .taken)
        ]

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 3,
            breakDays: 0,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
        mockRepository.cycles = [cycle]
        mockUserDefaultsManager.pillInfo = PillInfo(name: "테스트약", takingDays: 3, breakDays: 0)

        // When: 통계 조회
        let result = try sut.execute()
            .toBlocking()
            .first()

        // Then: 복용률 100%
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.first?.completionRate, 100)
        XCTAssertEqual(result?.first?.medicineName, "테스트약")
    }

    func test_복용률_부분복용_계산() throws {
        // Given: 3일 중 2일만 복용
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let records = [
            createRecord(scheduledDate: startDate, cycleDay: 1, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 1, to: startDate)!, cycleDay: 2, status: .missed),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 2, to: startDate)!, cycleDay: 3, status: .taken)
        ]

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 3,
            breakDays: 0,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
        mockRepository.cycles = [cycle]
        mockUserDefaultsManager.pillInfo = PillInfo(name: "테스트약", takingDays: 3, breakDays: 0)

        // When: 통계 조회
        let result = try sut.execute()
            .toBlocking()
            .first()

        // Then: 복용률 66% (2/3)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.first?.completionRate, 66)
    }

    // MARK: - 통계 카테고리 분류 테스트

    func test_정시복용_지연복용_미복용_각각_분류() throws {
        // Given: 다양한 복용 상태
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let records = [
            createRecord(scheduledDate: startDate, cycleDay: 1, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 1, to: startDate)!, cycleDay: 2, status: .takenDelayed),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 2, to: startDate)!, cycleDay: 3, status: .missed),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 3, to: startDate)!, cycleDay: 4, status: .taken)
        ]

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 4,
            breakDays: 0,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
        mockRepository.cycles = [cycle]
        mockUserDefaultsManager.pillInfo = PillInfo(name: "테스트약", takingDays: 4, breakDays: 0)

        // When: 통계 조회
        let result = try sut.execute()
            .toBlocking()
            .first()

        // Then: 카테고리별 분류 확인
        XCTAssertNotNil(result)
        let recordItems = result?.first?.records ?? []

        // 정시 복용: 2일 (50%)
        let onTimeRecord = recordItems.first { $0.category == "정시에 복용했어요" }
        XCTAssertNotNil(onTimeRecord)
        XCTAssertEqual(onTimeRecord?.days, 2)
        XCTAssertEqual(onTimeRecord?.percentage, 50)

        // 조금 늦음: 1일 (25%)
        let lateRecord = recordItems.first { $0.category == "조금 늦었어요" }
        XCTAssertNotNil(lateRecord)
        XCTAssertEqual(lateRecord?.days, 1)
        XCTAssertEqual(lateRecord?.percentage, 25)

        // 미복용: 1일 (25%)
        let missedRecord = recordItems.first { $0.category == "미복용 및 2알 복용" }
        XCTAssertNotNil(missedRecord)
        XCTAssertEqual(missedRecord?.days, 1)
        XCTAssertEqual(missedRecord?.percentage, 25)
    }

    func test_휴약일_제외하고_통계_계산() throws {
        // Given: 활성일 3일 + 휴약일 2일
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let records = [
            createRecord(scheduledDate: startDate, cycleDay: 1, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 1, to: startDate)!, cycleDay: 2, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 2, to: startDate)!, cycleDay: 3, status: .taken),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 3, to: startDate)!, cycleDay: 4, status: .rest),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 4, to: startDate)!, cycleDay: 5, status: .rest)
        ]

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 3,
            breakDays: 2,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
        mockRepository.cycles = [cycle]
        mockUserDefaultsManager.pillInfo = PillInfo(name: "테스트약", takingDays: 3, breakDays: 2)

        // When: 통계 조회
        let result = try sut.execute()
            .toBlocking()
            .first()

        // Then: 휴약일 제외한 3일 기준으로 100% 계산
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.first?.completionRate, 100)

        let recordItems = result?.first?.records ?? []
        let onTimeRecord = recordItems.first { $0.category == "정시에 복용했어요" }
        XCTAssertEqual(onTimeRecord?.days, 3) // 휴약일 제외
    }

    func test_빈_사이클_isEmpty_true_반환() throws {
        // Given: 모든 레코드가 scheduled인 사이클
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 9))!

        let records = [
            createRecord(scheduledDate: startDate, cycleDay: 1, status: .scheduled),
            createRecord(scheduledDate: calendar.date(byAdding: .day, value: 1, to: startDate)!, cycleDay: 2, status: .scheduled)
        ]

        let cycle = Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 2,
            breakDays: 0,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
        mockRepository.cycles = [cycle]
        mockUserDefaultsManager.pillInfo = PillInfo(name: "테스트약", takingDays: 2, breakDays: 0)

        // When: 통계 조회
        let result = try sut.execute()
            .toBlocking()
            .first()

        // Then: isEmpty = true, completionRate = 0
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.first?.isEmpty, true)
        XCTAssertEqual(result?.first?.completionRate, 0)
    }

    // MARK: - Helper Methods

    private func createRecord(
        scheduledDate: Date,
        cycleDay: Int,
        status: PillStatus,
        takenAt: Date? = nil
    ) -> DayRecord {
        return DayRecord(
            id: UUID(),
            cycleDay: cycleDay,
            status: status,
            scheduledDateTime: scheduledDate,
            takenAt: takenAt,
            memo: "",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Repository

final class MockCycleHistoryRepository: CycleHistoryProtocol {
    var cycles: [Cycle] = []

    func fetchAllCycles() throws -> [Cycle] {
        return cycles
    }

    func save(_ cycle: Cycle) throws {}
    func delete(_ cycleId: UUID) throws {}
}

// MARK: - Mock UserDefaults Manager

final class MockUserDefaultsManager: UserDefaultsManagerProtocol {
    var pillInfo: PillInfo?
    var sideEffectTags: [SideEffectTag] = []
    var pillStartDate: Date?
    var currentCycleID: UUID?
    var completedOnboarding = false

    func savePillInfo(_ pillInfo: PillInfo) {
        self.pillInfo = pillInfo
    }

    func savePillStartDate(_ date: Date) {
        self.pillStartDate = date
    }

    func loadPillInfo() -> PillInfo? {
        return pillInfo
    }

    func loadPillStartDate() -> Date? {
        return pillStartDate
    }

    func clearPillSettings() {
        pillInfo = nil
        pillStartDate = nil
    }

    func saveCurrentCycleID(_ id: UUID) {
        self.currentCycleID = id
    }

    func loadCurrentCycleID() -> UUID? {
        return currentCycleID
    }

    func hasCompletedOnboarding() -> Bool {
        return completedOnboarding
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        completedOnboarding = completed
    }

    func saveSideEffectTags(_ tags: [SideEffectTag]) {
        self.sideEffectTags = tags
    }

    func loadSideEffectTags() -> [SideEffectTag] {
        return sideEffectTags
    }
}
