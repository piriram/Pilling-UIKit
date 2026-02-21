import XCTest
import RxSwift
import RxBlocking
@testable import PillingApp

final class UpdatePillStatusUseCaseTests: XCTestCase {
    var sut: UpdatePillStatusUseCase!
    var mockTimeProvider: MockTimeProvider!
    var mockRepository: MockCycleRepository!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockTimeProvider = MockTimeProvider()
        mockRepository = MockCycleRepository()
        sut = UpdatePillStatusUseCase(
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

    // MARK: - 과거 날짜 자동 변환 테스트

    func test_과거날짜를_Scheduled로_변경시도_자동으로_Missed_변환() throws {
        // Given: 2024-01-10에 복용 예정이었던 레코드
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .notTaken)

        // When: 2024-01-12에 scheduled로 변경 시도 (과거 날짜)
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 12, hour: 10))!
        mockTimeProvider.now = currentDate

        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .scheduled,
            memo: nil,
            takenAt: nil
        )
        .toBlocking()
        .first()

        // Then: 자동으로 missed로 변환
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .missed)
    }

    func test_과거날짜를_NotTaken으로_변경시도_자동으로_Missed_변환() throws {
        // Given: 2024-01-10에 복용 예정이었던 레코드
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .scheduled)

        // When: 2024-01-12에 notTaken으로 변경 시도 (과거 날짜)
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 12, hour: 10))!
        mockTimeProvider.now = currentDate

        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .notTaken,
            memo: nil,
            takenAt: nil
        )
        .toBlocking()
        .first()

        // Then: 자동으로 missed로 변환
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .missed)
    }

    func test_오늘날짜를_Scheduled로_변경_정상적으로_업데이트() throws {
        // Given: 2024-01-10에 복용 예정인 레코드
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .notTaken)

        // When: 같은 날 scheduled로 변경
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 8))!
        mockTimeProvider.now = currentDate

        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .scheduled,
            memo: nil,
            takenAt: nil
        )
        .toBlocking()
        .first()

        // Then: scheduled로 정상 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .scheduled)
    }

    // MARK: - 상태 업데이트 테스트

    func test_상태변경_정상적으로_업데이트() throws {
        // Given: scheduled 상태의 레코드
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .scheduled)

        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 10))!
        mockTimeProvider.now = currentDate

        // When: taken으로 변경
        let takenAt = currentDate
        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .taken,
            memo: "복용했어요",
            takenAt: takenAt
        )
        .toBlocking()
        .first()

        // Then: taken으로 업데이트, takenAt과 memo도 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .taken)
        XCTAssertEqual(updatedRecord?.takenAt, takenAt)
        XCTAssertEqual(updatedRecord?.memo, "복용했어요")
    }

    func test_메모만_업데이트() throws {
        // Given: scheduled 상태의 레코드
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .scheduled)

        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 8))!
        mockTimeProvider.now = currentDate

        // When: 메모만 변경
        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .scheduled,
            memo: "나중에 복용",
            takenAt: nil
        )
        .toBlocking()
        .first()

        // Then: 상태는 그대로, 메모만 업데이트
        XCTAssertNotNil(result)
        let updatedRecord = result?.records.first
        XCTAssertEqual(updatedRecord?.status, .scheduled)
        XCTAssertEqual(updatedRecord?.memo, "나중에 복용")
    }

    func test_잘못된_인덱스_원본_사이클_반환() throws {
        // Given: 레코드가 1개인 사이클
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let cycle = createTestCycle(scheduledDate: scheduledDate, status: .scheduled)

        // When: 잘못된 인덱스로 업데이트 시도
        let result = try sut.execute(
            cycle: cycle,
            recordIndex: 99,
            newStatus: .taken,
            memo: nil,
            takenAt: nil
        )
        .toBlocking()
        .first()

        // Then: 원본 사이클 반환 (변경 없음)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.records.count, 1)
        XCTAssertEqual(result?.records.first?.status, .scheduled)
    }

    // MARK: - Helper Methods

    private func createTestCycle(scheduledDate: Date, status: PillStatus) -> Cycle {
        let record = DayRecord(
            id: UUID(),
            cycleDay: 1,
            status: status,
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
