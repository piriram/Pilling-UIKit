import XCTest
@testable import PillingApp

final class CalculateMessageUseCaseTests: XCTestCase {
    var sut: CalculateMessageUseCase!
    var mockTimeProvider: MockTimeProvider!
    var statusFactory: PillStatusFactory!

    override func setUp() {
        super.setUp()
        mockTimeProvider = MockTimeProvider()
        statusFactory = PillStatusFactory(timeProvider: mockTimeProvider)
        sut = CalculateMessageUseCase(
            statusFactory: statusFactory,
            timeProvider: mockTimeProvider
        )
    }

    override func tearDown() {
        sut = nil
        mockTimeProvider = nil
        statusFactory = nil
        super.tearDown()
    }

    // MARK: - 사이클 시작 전 테스트

    func test_사이클시작전_BeforeStart_메시지_반환() {
        // Given: 사이클 시작일이 2024-01-15
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 9))!
        let cycle = createTestCycle(startDate: startDate, records: [])

        // When: 2024-01-10에 평가 (5일 전)
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!
        mockTimeProvider.now = currentDate

        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: beforeStart 메시지
        let expectedText = MessageType.beforeStart(daysUntilStart: 5).text
        XCTAssertEqual(result.text, expectedText)
    }

    // MARK: - 휴약일 테스트

    func test_휴약일_Resting_메시지_반환() {
        // Given: 2024-01-10이 휴약일
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .rest
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: resting 메시지
        XCTAssertEqual(result.text, MessageType.resting.text)
    }

    // MARK: - 정시 복용 테스트

    func test_정시복용_TodayAfter_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .taken,
            takenAt: takenAt
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 복용 후 평가
        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        // Then: todayAfter 메시지
        XCTAssertEqual(result.text, MessageType.todayAfter.text)
    }

    func test_너무일찍복용_TakenTooEarly_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정, 06:30에 복용
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 6, minute: 30))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .takenTooEarly,
            takenAt: takenAt
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 복용 후 평가
        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        // Then: takenTooEarly 메시지
        XCTAssertEqual(result.text, MessageType.takenTooEarly.text)
    }

    func test_지연복용_TakenDelayedOk_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정, 10:00에 복용
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 10))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .takenDelayed,
            takenAt: takenAt
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 복용 후 평가
        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        // Then: takenDelayedOk 메시지
        XCTAssertEqual(result.text, MessageType.takenDelayedOk.text)
    }

    // MARK: - 시간 기반 메시지 테스트

    func test_미복용_정시_PlantingSeed_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .scheduled
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 복용 예정 시각 직후 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: plantingSeed 메시지 (복용 권유)
        XCTAssertEqual(result.text, MessageType.plantingSeed.text)
    }

    func test_미복용_2시간초과_OverTwoHours_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 11, minute: 10))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .notTaken
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 2시간 초과 후 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: overTwoHours 메시지
        XCTAssertEqual(result.text, MessageType.overTwoHours.text)
    }

    func test_미복용_4시간초과_OverFourHours_메시지_반환() {
        // Given: 2024-01-10 09:00에 복용 예정
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 13, minute: 30))!

        let record = createRecord(
            scheduledDate: scheduledDate,
            status: .notTaken
        )
        let cycle = createTestCycle(startDate: scheduledDate, records: [record])

        // When: 4시간 초과 후 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: overFourHours 메시지
        XCTAssertEqual(result.text, MessageType.overFourHours.text)
    }

    // MARK: - 어제 놓침 시나리오 테스트

    func test_어제놓침_오늘미복용_PilledTwo_메시지_반환() {
        // Given: 어제(01-09) missed, 오늘(01-10) 미복용
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let todayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!

        let yesterdayRecord = createRecord(
            scheduledDate: yesterdayDate,
            status: .missed
        )
        let todayRecord = createRecord(
            scheduledDate: todayDate,
            status: .notTaken
        )
        let cycle = createTestCycle(startDate: yesterdayDate, records: [yesterdayRecord, todayRecord])

        // When: 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: pilledTwo 메시지 (2알 복용 권유)
        XCTAssertEqual(result.text, MessageType.pilledTwo.text)
    }

    func test_어제놓침_오늘1알복용_Warning_메시지_반환() {
        // Given: 어제(01-09) missed, 오늘(01-10) 1알 복용
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let todayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!

        let yesterdayRecord = createRecord(
            scheduledDate: yesterdayDate,
            status: .missed
        )
        let todayRecord = createRecord(
            scheduledDate: todayDate,
            status: .taken,
            takenAt: takenAt
        )
        let cycle = createTestCycle(startDate: yesterdayDate, records: [yesterdayRecord, todayRecord])

        // When: 평가
        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        // Then: warning 메시지 (2알 복용 필요 경고)
        XCTAssertEqual(result.text, MessageType.warning.text)
    }

    func test_어제놓침_오늘2알복용_TakingBefore_메시지_반환() {
        // Given: 어제(01-09) missed, 오늘(01-10) 2알 복용
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let todayDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let takenAt = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!

        let yesterdayRecord = createRecord(
            scheduledDate: yesterdayDate,
            status: .missed
        )
        let todayRecord = createRecord(
            scheduledDate: todayDate,
            status: .takenDouble,
            takenAt: takenAt
        )
        let cycle = createTestCycle(startDate: yesterdayDate, records: [yesterdayRecord, todayRecord])

        // When: 평가
        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        // Then: takingBefore 메시지 (보충 완료)
        XCTAssertEqual(result.text, MessageType.takingBefore.text)
    }

    // MARK: - 연속 미복용 테스트

    func test_연속2일미복용_Fire_메시지_반환() {
        // Given: 01-08, 01-09 missed, 01-10 미복용
        let calendar = Calendar.current
        let day8 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 8, hour: 9))!
        let day9 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let day10 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!

        let records = [
            createRecord(scheduledDate: day8, status: .missed),
            createRecord(scheduledDate: day9, status: .missed),
            createRecord(scheduledDate: day10, status: .notTaken)
        ]
        let cycle = createTestCycle(startDate: day8, records: records)

        // When: 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: fire 메시지 (긴급)
        XCTAssertEqual(result.text, MessageType.fire.text)
    }

    func test_연속3일이상미복용_Waiting_메시지_반환() {
        // Given: 01-07, 01-08, 01-09 missed, 01-10 미복용
        let calendar = Calendar.current
        let day7 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 7, hour: 9))!
        let day8 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 8, hour: 9))!
        let day9 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let day10 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!

        let records = [
            createRecord(scheduledDate: day7, status: .missed),
            createRecord(scheduledDate: day8, status: .missed),
            createRecord(scheduledDate: day9, status: .missed),
            createRecord(scheduledDate: day10, status: .notTaken)
        ]
        let cycle = createTestCycle(startDate: day7, records: records)

        // When: 평가
        mockTimeProvider.now = currentDate
        let result = sut.execute(cycle: cycle, for: currentDate)

        // Then: waiting 메시지 (포기 상태)
        XCTAssertEqual(result.text, MessageType.waiting.text)
    }

    // MARK: - Helper Methods

    private func createTestCycle(startDate: Date, records: [DayRecord]) -> Cycle {
        return Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 21,
            breakDays: 7,
            scheduledTime: "09:00",
            records: records,
            createdAt: Date()
        )
    }

    private func createRecord(
        scheduledDate: Date,
        status: PillStatus,
        takenAt: Date? = nil
    ) -> DayRecord {
        return DayRecord(
            id: UUID(),
            cycleDay: 1,
            status: status,
            scheduledDateTime: scheduledDate,
            takenAt: takenAt,
            memo: "",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
