import XCTest
@testable import PillingApp

final class READMEMessageRuleTests: XCTestCase {
    private var sut: CalculateMessageUseCase!
    private var mockTimeProvider: MockTimeProvider!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        mockTimeProvider = MockTimeProvider(now: Date(), calendar: calendar, timeZone: calendar.timeZone)
        sut = CalculateMessageUseCase(
            statusFactory: PillStatusFactory(timeProvider: mockTimeProvider),
            timeProvider: mockTimeProvider
        )
    }

    override func tearDown() {
        sut = nil
        mockTimeProvider = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - README-based message rule tests

    func test_readme_earlyTaking_returnsTakenTooEarlyMessage() {
        let scheduled = makeDate(2024, 1, 10, 9, 0)
        let takenAt = makeDate(2024, 1, 10, 6, 30) // >2h early
        let record = makeRecord(scheduledDate: scheduled, status: .takenTooEarly, takenAt: takenAt)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 10, 0, 0), records: [record])

        mockTimeProvider.now = takenAt
        let result = sut.execute(cycle: cycle, for: takenAt)

        XCTAssertEqual(result.text, MessageType.takenTooEarly.text)
    }

    func test_readme_restDay_returnsRestingMessage() {
        let scheduled = makeDate(2024, 1, 25, 9, 0)
        let current = makeDate(2024, 1, 25, 12, 0)
        let record = makeRecord(scheduledDate: scheduled, status: .rest)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: [record])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.resting.text)
    }

    func test_readme_consecutiveMissedTwoDays_returnsAngryMessage() {
        let day8 = makeDate(2024, 1, 8, 9, 0)
        let day9 = makeDate(2024, 1, 9, 9, 0)
        let day10 = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 12, 0)

        let records = [
            makeRecord(scheduledDate: day8, status: .missed),
            makeRecord(scheduledDate: day9, status: .missed),
            makeRecord(scheduledDate: day10, status: .notTaken)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, AppStrings.Message.noRecordForDays(2))
    }

    func test_readme_yesterdayMissed_todayNotTaken_returnsTakeTwoMessage() {
        let yesterday = makeDate(2024, 1, 9, 9, 0)
        let today = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 9, 10)

        let records = [
            makeRecord(scheduledDate: yesterday, status: .missed),
            makeRecord(scheduledDate: today, status: .notTaken)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text)
    }

    func test_readme_yesterdayMissed_todayTaken_returnsNeedOneMoreMessage() {
        let yesterday = makeDate(2024, 1, 9, 9, 0)
        let today = makeDate(2024, 1, 10, 9, 0)
        let takenAt = makeDate(2024, 1, 10, 9, 10)
        let current = makeDate(2024, 1, 10, 23, 0)

        let records = [
            makeRecord(scheduledDate: yesterday, status: .missed),
            makeRecord(scheduledDate: today, status: .taken, takenAt: takenAt)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.warning.text)
    }

    func test_readme_timeBased_todayOnTimeNotTaken_returnsPlantingSeed() {
        let scheduled = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 9, 10)
        let record = makeRecord(scheduledDate: scheduled, status: .notTaken)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: [record])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.plantingSeed.text)
    }

    func test_readme_timeBased_exactlyTwoHoursLate_returnsOverTwoHours() {
        let scheduled = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 11, 0)
        let record = makeRecord(scheduledDate: scheduled, status: .notTaken)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: [record])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.overTwoHours.text)
    }

    func test_readme_timeBased_exactlyFourHoursLate_returnsOverFourHours() {
        let scheduled = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 13, 0)
        let record = makeRecord(scheduledDate: scheduled, status: .notTaken)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: [record])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.overFourHours.text)
    }

    func test_readme_timeBased_exactlyTwelveHoursLate_returnsWaiting() {
        let scheduled = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 21, 0)
        let record = makeRecord(scheduledDate: scheduled, status: .notTaken)
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: [record])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.waiting.text)
    }

    func test_readme_consecutiveMissedThreeDays_returnsWaiting() {
        let day7 = makeDate(2024, 1, 7, 9, 0)
        let day8 = makeDate(2024, 1, 8, 9, 0)
        let day9 = makeDate(2024, 1, 9, 9, 0)
        let day10 = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 10, 12, 0)

        let records = [
            makeRecord(scheduledDate: day7, status: .missed),
            makeRecord(scheduledDate: day8, status: .missed),
            makeRecord(scheduledDate: day9, status: .missed),
            makeRecord(scheduledDate: day10, status: .notTaken)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.waiting.text)
    }

    func test_readme_yesterdayMissed_todayTakenTooEarly_returnsTakenTooEarly() {
        let yesterday = makeDate(2024, 1, 9, 9, 0)
        let todayScheduled = makeDate(2024, 1, 10, 9, 0)
        let takenAt = makeDate(2024, 1, 10, 6, 30)
        let current = takenAt

        let records = [
            makeRecord(scheduledDate: yesterday, status: .missed),
            makeRecord(scheduledDate: todayScheduled, status: .takenTooEarly, takenAt: takenAt)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.morePill.text)
    }

    func test_readme_yesterdayMissed_todayTakenDelayed_returnsMorePill() {
        let yesterday = makeDate(2024, 1, 9, 9, 0)
        let todayScheduled = makeDate(2024, 1, 10, 9, 0)
        let takenAt = makeDate(2024, 1, 10, 13, 30)
        let current = takenAt

        let records = [
            makeRecord(scheduledDate: yesterday, status: .missed),
            makeRecord(scheduledDate: todayScheduled, status: .takenDelayed, takenAt: takenAt)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.morePill.text)
    }

    func test_readme_yesterdayMissed_todayTakenDouble_returnsTakenDoubleComplete() {
        let yesterday = makeDate(2024, 1, 9, 9, 0)
        let todayScheduled = makeDate(2024, 1, 10, 9, 0)
        let takenAt = makeDate(2024, 1, 10, 9, 10)
        let current = takenAt

        let records = [
            makeRecord(scheduledDate: yesterday, status: .missed),
            makeRecord(scheduledDate: todayScheduled, status: .takenDouble, takenAt: takenAt)
        ]
        let cycle = makeCycle(startDate: makeDate(2024, 1, 1, 0, 0), records: records)

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.takenDoubleComplete.text)
    }

    func test_readme_beforeStart_returnsBeforeStartMessage() {
        let startDate = makeDate(2024, 1, 10, 9, 0)
        let current = makeDate(2024, 1, 5, 12, 0)
        let cycle = makeCycle(startDate: startDate, records: [])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.beforeStart(daysUntilStart: 4).text)
    }

    func test_readme_cycleComplete_returnsCycleCompleteMessage() {
        let startDate = makeDate(2024, 1, 1, 0, 0)
        let current = makeDate(2024, 1, 30, 12, 0)
        let cycle = makeCycle(startDate: startDate, records: [])

        mockTimeProvider.now = current
        let result = sut.execute(cycle: cycle, for: current)

        XCTAssertEqual(result.text, MessageType.cycleComplete.text)
    }


    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )) ?? Date()
    }

    private func makeCycle(startDate: Date, records: [DayRecord]) -> Cycle {
        return Cycle(
            id: UUID(),
            cycleNumber: 1,
            startDate: startDate,
            activeDays: 24,
            breakDays: 4,
            scheduledTime: "09:00",
            records: records,
            createdAt: startDate
        )
    }

    private func makeRecord(
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
            createdAt: scheduledDate,
            updatedAt: scheduledDate
        )
    }
}
