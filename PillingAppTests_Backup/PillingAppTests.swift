import XCTest

final class PillingAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // 아주 간단한 테스트
        XCTAssertTrue(true)
        print("✅ 테스트가 실행되었습니다!")
    }

    func testBasicMath() throws {
        let result = 2 + 2
        XCTAssertEqual(result, 4)
        print("✅ 기본 연산 테스트 통과!")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
