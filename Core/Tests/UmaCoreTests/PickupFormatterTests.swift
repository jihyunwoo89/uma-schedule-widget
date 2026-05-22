import XCTest
@testable import UmaCore

final class PickupFormatterTests: XCTestCase {
    func test_trainee_trailingStar() {
        let r = PickupFormatter.trainee("발렌타인 애스턴 마짱 3★")
        XCTAssertEqual(r.stars, 3)
        XCTAssertEqual(r.name, "발렌타인 애스턴 마짱")
    }
    func test_trainee_embeddedStar_collapsesWhitespace() {
        let r = PickupFormatter.trainee("천장시 3★ 택 1")
        XCTAssertEqual(r.stars, 3)
        XCTAssertEqual(r.name, "천장시 택 1")
    }
    func test_trainee_noStar_returnsNilAndName() {
        let r = PickupFormatter.trainee("어떤 우마무스메")
        XCTAssertNil(r.stars)
        XCTAssertEqual(r.name, "어떤 우마무스메")
    }
    func test_trainee_starWithSpaceBeforeMark() {
        let r = PickupFormatter.trainee("이름 2 ★")
        XCTAssertEqual(r.stars, 2)
        XCTAssertEqual(r.name, "이름")
    }
    func test_trainee_leadingStar() {
        let r = PickupFormatter.trainee("1★ 이름")
        XCTAssertEqual(r.stars, 1)
        XCTAssertEqual(r.name, "이름")
    }
}
