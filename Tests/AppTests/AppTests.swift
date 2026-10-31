@testable import HTML2Text
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

    func testLinkedImage_referenceStyleWithWhitespace() throws {
        let html =
            "<a href=\"https://example.com/page\"><img src=\"https://example.com/banner.jpg\" alt=\"Banner image\"></a>"
        let h = HTML2Text(baseurl: "https://example.com")
        h.inline_links = false
        let result = h.main(baseurl: "https://example.com", data: html)
        XCTAssertTrue(
            result.contains("[![Banner image][1]][2]"),
            "Linked reference images should not get an extra opening bracket from whitespace"
        )
        XCTAssertFalse(
            result.contains("[ [![Banner image]"),
            "Should not contain broken linked image markup"
        )
    }

    func testEmptyAnchor_referenceStyleOmitsLink() throws {
        let html = "<a href=\"https://example.com/\"></a>Mastodon"
        let h = HTML2Text(baseurl: "")
        h.inline_links = false
        h.links_each_paragraph = true
        let result = h.main(baseurl: "", data: html)
        XCTAssertEqual(
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            "Mastodon"
        )
        XCTAssertFalse(result.contains("]["), "Empty anchor must not emit a bare reference")
        XCTAssertFalse(
            result.contains("https://example.com/"),
            "Empty anchor must not add a reference definition"
        )
    }

    func testAnchorWithText_referenceStyleStillEmitsLink() throws {
        let html = "<a href=\"https://example.com/\">Example</a>"
        let h = HTML2Text(baseurl: "")
        h.inline_links = false
        h.links_each_paragraph = true
        let result = h.main(baseurl: "", data: html)
        XCTAssertTrue(result.contains("[Example][1]"), "Anchor text should stay a reference link")
        XCTAssertTrue(
            result.contains("[1]: https://example.com/"),
            "Reference definition should still be written"
        )
    }

    func testAutomaticLink_staysAngleBracketLink() throws {
        let html = "<a href=\"https://example.com/\">https://example.com/</a>"
        let h = HTML2Text(baseurl: "")
        h.inline_links = false
        h.links_each_paragraph = true
        let result = h.main(baseurl: "", data: html)
        XCTAssertTrue(
            result.contains("<https://example.com/>"),
            "URL-as-text anchors should render as automatic links"
        )
        XCTAssertFalse(result.contains("]["), "Automatic links should not also be references")
        XCTAssertFalse(
            result.contains("[1]:"),
            "Automatic links should not add a reference definition"
        )
    }

    // MARK: - Blocks

    func testParagraphsAreSeparated() throws {
        XCTAssertEqual(rendered("<p>One</p><p>Two</p>"), "One\n\nTwo")
    }

    func testDivsAreSeparated() throws {
        XCTAssertEqual(rendered("<div>Block</div><div>Next</div>"), "Block\n\nNext")
    }

    func testHeadings() throws {
        let html = "<h1>Title</h1><h2>Section</h2><h3>Sub</h3><h4>Four</h4><h5>Five</h5><h6>Six</h6>"
        XCTAssertEqual(
            rendered(html),
            "# Title\n\n## Section\n\n### Sub\n\n#### Four\n\n##### Five\n\n###### Six"
        )
    }

    func testHeadingKeepsInnerEmphasis() throws {
        XCTAssertEqual(rendered("<h1><strong>Title</strong></h1>"), "# **Title**")
    }

    func testHorizontalRule() throws {
        XCTAssertEqual(rendered("<p>Above</p><hr><p>Below</p>"), "Above\n\n* * *\n\nBelow")
    }

    func testLineBreakBecomesMarkdownHardBreak() throws {
        let result = HTML2Text.process(html: "<p>Line one<br>Line two</p>", baseurl: nil)
        XCTAssertEqual(stripSurroundingNewlines(result), "Line one  \nLine two")
    }

    func testBlockquote() throws {
        XCTAssertEqual(rendered("<blockquote><p>Quoted</p></blockquote>"), "> Quoted")
    }

    func testNestedBlockquote() throws {
        let html = "<blockquote><p>Outer</p><blockquote><p>Inner</p></blockquote></blockquote>"
        XCTAssertEqual(rendered(html), "> Outer\n> \n> > Inner")
    }

    func testPreformattedIsIndented() throws {
        XCTAssertEqual(
            rendered("<pre>line one\n    line two</pre>"),
            "    line one\n        line two"
        )
    }

    func testCodeInsidePreDoesNotAddBackticks() throws {
        XCTAssertEqual(rendered("<pre><code>let x = 1</code></pre>"), "    let x = 1")
    }

    // MARK: - Inline

    func testEmphasisMarks() throws {
        let html = "<p><strong>Bold</strong> and <em>italic</em> and <b>b</b> <i>i</i> <u>u</u></p>"
        XCTAssertEqual(rendered(html), "**Bold** and _italic_ and **b** _i_ _u_")
    }

    func testNestedEmphasis() throws {
        XCTAssertEqual(
            rendered("<p><strong>bold <em>and italic</em></strong></p>"),
            "**bold _and italic_**"
        )
    }

    func testIgnoreEmphasis() throws {
        XCTAssertEqual(
            rendered("<p><strong>Bold</strong> <em>italic</em></p>", ignoreEmphasis: true),
            "Bold italic"
        )
    }

    func testAsteriskEmphasisOption() throws {
        XCTAssertEqual(
            rendered("<p><em>italic</em> <strong>bold</strong></p>", asteriskEmphasis: true),
            "*italic* __bold__"
        )
    }

    func testInlineCode() throws {
        XCTAssertEqual(rendered("<p>Use <code>npm test</code> here.</p>"), "Use `npm test` here.")
    }

    func testEscapeAllEscapesMarkdownCharacters() throws {
        XCTAssertEqual(
            rendered("<p>Use *stars* and _underscores_ #1</p>", escapeAll: true),
            "Use \\*stars\\* and \\_underscores\\_ \\#1"
        )
    }

    func testNamedEntitiesDecode() throws {
        XCTAssertEqual(
            rendered("<p>Tom &amp; Jerry &lt;3 &nbsp; space</p>"),
            "Tom & Jerry <3 space"
        )
    }

    func testStrikethroughIsLeftAsHtml() throws {
        XCTAssertEqual(
            rendered("<p><del>gone</del> <s>also</s> <strike>too</strike></p>"),
            "<del>gone</del> <s>also</s> <strike>too</strike>"
        )
    }

    func testAbbreviationDefinition() throws {
        XCTAssertEqual(
            rendered("<p><abbr title=\"HyperText Markup Language\">HTML</abbr></p>"),
            "HTML\n  *[HTML]: HyperText Markup Language"
        )
    }

    func testSuperscriptFootnoteMarker() throws {
        XCTAssertEqual(rendered("<p>Note<sup id=\"fnref:1\">1</sup></p>"), "Note[^1]")
    }

    func testScriptAndStyleAreOmitted() throws {
        let html = "<p>Visible</p><script>alert(1)</script><style>p { color: red }</style><p>Also</p>"
        let result = rendered(html)
        XCTAssertEqual(result, "Visible\n\nAlso")
        XCTAssertFalse(result.contains("alert"))
        XCTAssertFalse(result.contains("color"))
    }

    // MARK: - Lists

    func testUnorderedList() throws {
        XCTAssertEqual(rendered("<ul><li>A</li><li>B</li></ul>"), "- A\n- B")
    }

    func testOrderedList() throws {
        XCTAssertEqual(rendered("<ol><li>A</li><li>B</li></ol>"), "1. A\n2. B")
    }

    func testOrderedListStartAttribute() throws {
        XCTAssertEqual(rendered("<ol start=\"3\"><li>C</li><li>D</li></ol>"), "3. C\n4. D")
    }

    func testNestedList() throws {
        XCTAssertEqual(
            rendered("<ul><li>A<ul><li>A1</li></ul></li><li>B</li></ul>"),
            "- A\n    - A1\n- B"
        )
    }

    func testListMarkCanBeAnAsterisk() throws {
        XCTAssertEqual(
            rendered("<ul><li>A</li></ul>", configure: { $0.ul_item_mark = "*" }),
            "* A"
        )
    }

    // MARK: - Links and images

    func testInlineLink() throws {
        XCTAssertEqual(
            rendered("<p>See <a href=\"https://example.com/docs\">the docs</a>.</p>"),
            "See [the docs](https://example.com/docs)."
        )
    }

    func testInlineLinkDropsTitleAttribute() throws {
        XCTAssertEqual(
            rendered("<p><a href=\"https://example.com/\" title=\"Example\">Ex</a></p>"),
            "[Ex](https://example.com/)"
        )
    }

    func testInlineRelativeLinkStaysRelative() throws {
        XCTAssertEqual(
            rendered("<p><a href=\"/docs\">Docs</a></p>", baseurl: "https://example.com"),
            "[Docs](/docs)"
        )
    }

    func testReferenceLink() throws {
        XCTAssertEqual(
            rendered(
                "<p>See <a href=\"https://example.com/docs\">the docs</a>.</p>",
                configure: { $0.inline_links = false }
            ),
            "See [the docs][1].\n\n\n[1]: https://example.com/docs"
        )
    }

    func testReferenceLinkResolvesRootRelativeHref() throws {
        XCTAssertEqual(
            rendered(
                "<p><a href=\"/docs\">Docs</a></p>",
                baseurl: "https://example.com",
                configure: { $0.inline_links = false }
            ),
            "[Docs][1]\n\n\n[1]: https://example.com/docs"
        )
    }

    func testReferenceLinkResolvesProtocolRelativeHref() throws {
        XCTAssertEqual(
            rendered(
                "<p><a href=\"//cdn.example.com/a\">A</a></p>",
                baseurl: "https://example.com",
                configure: { $0.inline_links = false }
            ),
            "[A][1]\n\n\n[1]: https://cdn.example.com/a"
        )
    }

    func testDuplicateReferenceHrefsShareOneDefinition() throws {
        let html = "<p><a href=\"https://example.com/\">One</a> and <a href=\"https://example.com/\">Two</a></p>"
        XCTAssertEqual(
            rendered(html, configure: { $0.inline_links = false }),
            "[One][1] and [Two][1]\n\n\n[1]: https://example.com/"
        )
    }

    func testInternalLinksAreSkipped() throws {
        let html = "<p><a href=\"#section\">Section</a> and <a href=\"https://example.com/\">Out</a></p>"
        XCTAssertEqual(rendered(html), "Section and [Out](https://example.com/)")
    }

    func testFootnoteFragmentLinksAreKept() throws {
        XCTAssertEqual(rendered("<p><a href=\"#fn1\">1</a></p>"), "[1](#fn1)")
    }

    func testIgnoreLinksLeavesText() throws {
        XCTAssertEqual(
            rendered("<p><a href=\"https://example.com/\">Example</a></p>", ignoreLinks: true),
            "Example"
        )
    }

    func testEmptyAnchorInlineOmitsLink() throws {
        XCTAssertEqual(
            rendered("<p><a href=\"https://example.com/\"></a>Mastodon</p>"),
            "Mastodon"
        )
    }

    func testStrongWrappedLinkStaysOutsideTheBrackets() throws {
        XCTAssertEqual(
            rendered("<p><strong><a href=\"https://example.com/\">text</a></strong></p>"),
            "**[text](https://example.com/)**"
        )
    }

    func testFixbracketsMovesEmphasisInsideTheLink() throws {
        let h = HTML2Text()
        XCTAssertEqual(
            h.fixbrackets("See **[text**](https://example.com/) and _[other_](https://example.org/)."),
            "See [**text**](https://example.com/) and [_other_](https://example.org/)."
        )
        XCTAssertEqual(
            h.fixbrackets("**[text](https://example.com/)**"),
            "**[text](https://example.com/)**"
        )
    }

    func testImage() throws {
        XCTAssertEqual(
            rendered("<p><img src=\"https://example.com/shot.png\" alt=\"A shot\"></p>"),
            "![A shot](https://example.com/shot.png)"
        )
    }

    func testImageWithoutAlt() throws {
        XCTAssertEqual(
            rendered("<p><img src=\"https://example.com/shot.png\"></p>"),
            "![](https://example.com/shot.png)"
        )
    }

    func testIgnoreImagesDropsTheImage() throws {
        let html = "<p>Before <img src=\"https://example.com/shot.png\" alt=\"A shot\"> after</p>"
        XCTAssertEqual(rendered(html, ignoreImages: true), "Before  after")
    }

    func testReferenceImageResolvesRootRelativeSrc() throws {
        XCTAssertEqual(
            rendered(
                "<p><img src=\"/shot.png\" alt=\"A shot\"></p>",
                baseurl: "https://example.com",
                configure: { $0.inline_links = false }
            ),
            "![A shot][1]\n\n\n[1]: https://example.com/shot.png"
        )
    }

    // MARK: - Tables

    func testTableWithHeader() throws {
        let html = """
            <table><thead><tr><th>Name</th><th>Qty</th></tr></thead>\
            <tbody><tr><td>Apples</td><td>2</td></tr><tr><td>Pears</td><td>5</td></tr></tbody></table>
            """
        XCTAssertEqual(
            rendered(html),
            "| Name | Qty | \n| ---- | ----  |\n| Apples | 2 | \n| Pears | 5 | "
        )
    }

    func testTableWithoutHeader() throws {
        let html = "<table><tr><td>A</td><td>B</td></tr><tr><td>C</td><td>D</td></tr></table>"
        XCTAssertEqual(rendered(html), "| ----- |\n| A | B | \n| C | D | ")
    }

    func testFirstAttributeValueWins() throws {
        let h = HTML2Text(baseurl: "")
        XCTAssertEqual(
            h.firstAttributeValues([
                ("href", "https://a.example"),
                ("href", "https://b.example"),
                ("class", "ext"),
            ]),
            ["href": "https://a.example", "class": "ext"]
        )
    }

    func testDuplicateHrefDoesNotTrap() throws {
        let html = "<p><a href=\"https://example.com\" href=\"https://other.example\">Hello</a></p>"
        let result = HTML2Text.process(html: html, baseurl: nil)
        XCTAssertTrue(result.contains("Hello"))
    }

    func testFixheadlinesRepairsEachHeadlineSeparately() throws {
        let h = HTML2Text()
        let broken = """
            # [First
            ](https://example.com/a)

            ## [Second
            ](https://example.com/b)
            """
        XCTAssertEqual(
            h.fixheadlines(broken),
            """
            # [First](https://example.com/a)

            ## [Second](https://example.com/b)
            """
        )
    }

    private func rendered(
        _ html: String,
        baseurl: String = "",
        configure: ((HTML2Text) -> Void)? = nil,
        ignoreEmphasis: Bool = false,
        ignoreLinks: Bool = false,
        ignoreImages: Bool = false,
        asteriskEmphasis: Bool = false,
        escapeAll: Bool = false
    ) -> String {
        let h = HTML2Text(baseurl: baseurl)
        configure?(h)
        let result = h.main(
            baseurl: baseurl,
            data: html,
            ignoreEmphasis: ignoreEmphasis,
            ignoreLinks: ignoreLinks,
            ignoreImages: ignoreImages,
            asteriskEmphasis: asteriskEmphasis,
            escapeAll: escapeAll
        )
        return stripSurroundingNewlines(result)
    }

    private func stripSurroundingNewlines(_ text: String) -> String {
        var text = Substring(text)
        while text.first?.isNewline == true {
            text = text.dropFirst()
        }
        while text.last?.isNewline == true {
            text = text.dropLast()
        }
        return String(text)
    }

    static let allTests = [
        ("testNothing", testNothing),
        ("testDefinitionList_singleTermSingleDefinition", testDefinitionList_singleTermSingleDefinition),
        ("testDefinitionList_singleTermMultipleDefinitions", testDefinitionList_singleTermMultipleDefinitions),
        ("testDefinitionList_multipleTermsWithDefinitions", testDefinitionList_multipleTermsWithDefinitions),
        ("testDefinitionList_htmlInDtAndDd_convertedToMarkdown", testDefinitionList_htmlInDtAndDd_convertedToMarkdown),
        ("testDefinitionList_linksInDefinition", testDefinitionList_linksInDefinition),
        ("testLinkedImage_referenceStyleWithWhitespace", testLinkedImage_referenceStyleWithWhitespace),
        ("testEmptyAnchor_referenceStyleOmitsLink", testEmptyAnchor_referenceStyleOmitsLink),
        ("testAnchorWithText_referenceStyleStillEmitsLink", testAnchorWithText_referenceStyleStillEmitsLink),
        ("testAutomaticLink_staysAngleBracketLink", testAutomaticLink_staysAngleBracketLink),
        ("testParagraphsAreSeparated", testParagraphsAreSeparated),
        ("testDivsAreSeparated", testDivsAreSeparated),
        ("testHeadings", testHeadings),
        ("testHeadingKeepsInnerEmphasis", testHeadingKeepsInnerEmphasis),
        ("testHorizontalRule", testHorizontalRule),
        ("testLineBreakBecomesMarkdownHardBreak", testLineBreakBecomesMarkdownHardBreak),
        ("testBlockquote", testBlockquote),
        ("testNestedBlockquote", testNestedBlockquote),
        ("testPreformattedIsIndented", testPreformattedIsIndented),
        ("testCodeInsidePreDoesNotAddBackticks", testCodeInsidePreDoesNotAddBackticks),
        ("testEmphasisMarks", testEmphasisMarks),
        ("testNestedEmphasis", testNestedEmphasis),
        ("testIgnoreEmphasis", testIgnoreEmphasis),
        ("testAsteriskEmphasisOption", testAsteriskEmphasisOption),
        ("testInlineCode", testInlineCode),
        ("testEscapeAllEscapesMarkdownCharacters", testEscapeAllEscapesMarkdownCharacters),
        ("testNamedEntitiesDecode", testNamedEntitiesDecode),
        ("testStrikethroughIsLeftAsHtml", testStrikethroughIsLeftAsHtml),
        ("testAbbreviationDefinition", testAbbreviationDefinition),
        ("testSuperscriptFootnoteMarker", testSuperscriptFootnoteMarker),
        ("testScriptAndStyleAreOmitted", testScriptAndStyleAreOmitted),
        ("testUnorderedList", testUnorderedList),
        ("testOrderedList", testOrderedList),
        ("testOrderedListStartAttribute", testOrderedListStartAttribute),
        ("testNestedList", testNestedList),
        ("testListMarkCanBeAnAsterisk", testListMarkCanBeAnAsterisk),
        ("testInlineLink", testInlineLink),
        ("testInlineLinkDropsTitleAttribute", testInlineLinkDropsTitleAttribute),
        ("testInlineRelativeLinkStaysRelative", testInlineRelativeLinkStaysRelative),
        ("testReferenceLink", testReferenceLink),
        ("testReferenceLinkResolvesRootRelativeHref", testReferenceLinkResolvesRootRelativeHref),
        ("testReferenceLinkResolvesProtocolRelativeHref", testReferenceLinkResolvesProtocolRelativeHref),
        ("testDuplicateReferenceHrefsShareOneDefinition", testDuplicateReferenceHrefsShareOneDefinition),
        ("testInternalLinksAreSkipped", testInternalLinksAreSkipped),
        ("testFootnoteFragmentLinksAreKept", testFootnoteFragmentLinksAreKept),
        ("testIgnoreLinksLeavesText", testIgnoreLinksLeavesText),
        ("testEmptyAnchorInlineOmitsLink", testEmptyAnchorInlineOmitsLink),
        ("testStrongWrappedLinkStaysOutsideTheBrackets", testStrongWrappedLinkStaysOutsideTheBrackets),
        ("testFixbracketsMovesEmphasisInsideTheLink", testFixbracketsMovesEmphasisInsideTheLink),
        ("testFixheadlinesRepairsEachHeadlineSeparately", testFixheadlinesRepairsEachHeadlineSeparately),
        ("testImage", testImage),
        ("testImageWithoutAlt", testImageWithoutAlt),
        ("testIgnoreImagesDropsTheImage", testIgnoreImagesDropsTheImage),
        ("testReferenceImageResolvesRootRelativeSrc", testReferenceImageResolvesRootRelativeSrc),
        ("testTableWithHeader", testTableWithHeader),
        ("testTableWithoutHeader", testTableWithoutHeader),
        ("testFirstAttributeValueWins", testFirstAttributeValueWins),
        ("testDuplicateHrefDoesNotTrap", testDuplicateHrefDoesNotTrap),
    ]
}
