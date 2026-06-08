import XCTest
@testable import UmaCore

final class GradeParseTests: XCTestCase {
    func test_leadingGrade_splitsTokenAndName() {
        let (g1, n1) = GradeParse.leading("G1 벚꽃상")
        XCTAssertEqual(g1, "G1"); XCTAssertEqual(n1, "벚꽃상")
        let (g2, n2) = GradeParse.leading("G2 알헴붓슈상")
        XCTAssertEqual(g2, "G2"); XCTAssertEqual(n2, "알헴붓슈상")
        let (g3, n3) = GradeParse.leading("G3 어떤상")
        XCTAssertEqual(g3, "G3"); XCTAssertEqual(n3, "어떤상")
        let (op, n4) = GradeParse.leading("OP 오픈상")
        XCTAssertEqual(op, "OP"); XCTAssertEqual(n4, "오픈상")
    }
    func test_leadingGrade_noToken_returnsNilAndTrimmedName() {
        let (g, n) = GradeParse.leading("스프린트")
        XCTAssertNil(g); XCTAssertEqual(n, "스프린트")
    }
    func test_leadingGrade_trimsSurroundingWhitespace() {
        let (g, n) = GradeParse.leading("  G1   재팬컵  ")
        XCTAssertEqual(g, "G1"); XCTAssertEqual(n, "재팬컵")
    }
    func test_leadingGrade_doesNotMatchEmbeddedToken() {
        let (g, n) = GradeParse.leading("스프린터즈 G1")
        XCTAssertNil(g); XCTAssertEqual(n, "스프린터즈 G1")
    }
    func test_leadingGrade_doesNotMatchPartialWord() {
        let (g, n) = GradeParse.leading("G1234컵")
        XCTAssertNil(g); XCTAssertEqual(n, "G1234컵")
    }
    func test_leadingGrade_tokenOnly() {
        let (g, n) = GradeParse.leading("G1")
        XCTAssertEqual(g, "G1"); XCTAssertEqual(n, "")
    }
}
