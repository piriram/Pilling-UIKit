import XCTest
@testable import PillingApp

final class PillStatusFactoryTests: XCTestCase {
    var sut: PillStatusFactory!
    var mockTimeProvider: MockTimeProvider!

    override func setUp() {
        super.setUp()
        mockTimeProvider = MockTimeProvider()
        sut = PillStatusFactory(timeProvider: mockTimeProvider)
    }

    override func tearDown() {
        sut = nil
        mockTimeProvider = nil
        super.tearDown()
    }

    // MARK: - TimeContext 테스트

    func test_과거날짜_Past_TimeContext_반환() {
        // Given: 현재 시각이 2024-01-10 12:00
        let calendar = Calendar.current
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!
        mockTimeProvider.now = currentDate

        // When: 2024-01-09의 상태를 평가
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            evaluationDate: currentDate
        )

        // Then: TimeContext가 past여야 함
        XCTAssertEqual(status.timeContext, .past)
    }

    func test_미래날짜_Future_TimeContext_반환() {
        // Given: 현재 시각이 2024-01-10 12:00
        let calendar = Calendar.current
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!
        mockTimeProvider.now = currentDate

        // When: 2024-01-11의 상태를 평가
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 11, hour: 9))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            evaluationDate: currentDate
        )

        // Then: TimeContext가 future여야 함
        XCTAssertEqual(status.timeContext, .future)
    }

    func test_오늘날짜_Present_TimeContext_반환() {
        // Given: 현재 시각이 2024-01-10 12:00
        let calendar = Calendar.current
        let currentDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!
        mockTimeProvider.now = currentDate

        // When: 2024-01-10의 상태를 평가
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            evaluationDate: currentDate
        )

        // Then: TimeContext가 present여야 함
        XCTAssertEqual(status.timeContext, .present)
    }

    // MARK: - 복용 상태 테스트

    func test_정시복용_Taken_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!

        // When: 09:10에 복용 (10분 늦음, 정상 범위)
        let actionDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9, minute: 10))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: actionDate,
            evaluationDate: actionDate
        )

        // Then: taken 상태여야 함
        XCTAssertEqual(status.baseStatus, .taken)
    }

    func test_너무일찍복용_TakenTooEarly_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!

        // When: 06:30에 복용 (2시간 30분 빠름)
        let actionDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 6, minute: 30))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: actionDate,
            evaluationDate: actionDate
        )

        // Then: takenTooEarly 상태여야 함
        XCTAssertEqual(status.baseStatus, .takenTooEarly)
    }

    func test_늦게복용_TakenDelayed_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!

        // When: 10:00에 복용 (1시간 늦음)
        let actionDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 10))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: actionDate,
            evaluationDate: actionDate
        )

        // Then: takenDelayed 상태여야 함
        XCTAssertEqual(status.baseStatus, .takenDelayed)
    }

    func test_미복용_지나지않음_Scheduled_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!

        // When: 08:00에 평가 (아직 시간 전)
        let evaluationDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 8))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: nil,
            evaluationDate: evaluationDate
        )

        // Then: scheduled 상태여야 함
        XCTAssertEqual(status.baseStatus, .scheduled)
    }

    func test_미복용_시간초과_Missed_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!

        // When: 다음날 10:00에 평가 (완전히 놓침, 24시간 이상 경과)
        let evaluationDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 11, hour: 10))!
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: nil,
            evaluationDate: evaluationDate
        )

        // Then: missed 상태여야 함
        XCTAssertEqual(status.baseStatus, .missed)
    }

    func test_휴약일_Rest_상태_반환() {
        // Given: 예정 시각이 2024-01-10 09:00
        let calendar = Calendar.current
        let scheduledDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 9))!
        let evaluationDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12))!

        // When: 휴약일로 설정
        let status = sut.createStatus(
            scheduledDate: scheduledDate,
            actionDate: nil,
            evaluationDate: evaluationDate,
            isRestDay: true
        )

        // Then: rest 상태여야 함
        XCTAssertEqual(status.baseStatus, .rest)
    }
}
