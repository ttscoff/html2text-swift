import HTML2Text
import XCTest

final class AppTests: XCTestCase {

    func testNothing() throws {
        XCTAssert(true)
    }

    // MARK: - Definition list (dl/dt/dd) tests

    func testDefinitionList_singleTermSingleDefinition() throws {
        let html = "<dl><dt>Term</dt><dd>definition</dd></dl>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        let expected = """
            Term
            : definition
            """
        XCTAssertEqual(
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testDefinitionList_singleTermMultipleDefinitions() throws {
        let html = "<dl><dt>Term</dt><dd>definition</dd><dd>definition two</dd></dl>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        let expected = """
            Term
            : definition
            : definition two
            """
        XCTAssertEqual(
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testDefinitionList_multipleTermsWithDefinitions() throws {
        let html = "<dl><dt>Term</dt><dd>definition</dd><dt>Term2</dt><dd>def2</dd></dl>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        let expected = """
            Term
            : definition
            Term2
            : def2
            """
        XCTAssertEqual(
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testDefinitionList_htmlInDtAndDd_convertedToMarkdown() throws {
        let html =
            "<dl><dt><strong>Bold term</strong></dt><dd>Plain and <em>italic</em> definition</dd></dl>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        // Term should be **Bold term**, definition should have _italic_
        XCTAssertTrue(
            result.contains("**Bold term**"), "dt content should be converted to Markdown")
        XCTAssertTrue(result.contains("_italic_"), "dd content should be converted to Markdown")
        XCTAssertTrue(
            result.contains(": Plain and _italic_ definition")
                || result.contains(": Plain and _italic_"),
            "dd should be prefixed with ': ' and contain converted Markdown")
    }

    func testDefinitionList_linksInDefinition() throws {
        let html =
            "<dl><dt>Term</dt><dd>See <a href=\"https://example.com\">example</a> for more.</dd></dl>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        XCTAssertTrue(result.contains(": "), "dd should start with ': '")
        XCTAssertTrue(
            result.contains("example") || result.contains("[example]"), "Link text should appear")
    }

    static let allTests = [
        ("testNothing", testNothing),
        (
            "testDefinitionList_singleTermSingleDefinition",
            testDefinitionList_singleTermSingleDefinition
        ),
        (
            "testDefinitionList_singleTermMultipleDefinitions",
            testDefinitionList_singleTermMultipleDefinitions
        ),
        (
            "testDefinitionList_multipleTermsWithDefinitions",
            testDefinitionList_multipleTermsWithDefinitions
        ),
        (
            "testDefinitionList_htmlInDtAndDd_convertedToMarkdown",
            testDefinitionList_htmlInDtAndDd_convertedToMarkdown
        ),
        ("testDefinitionList_linksInDefinition", testDefinitionList_linksInDefinition),
    ]
}
