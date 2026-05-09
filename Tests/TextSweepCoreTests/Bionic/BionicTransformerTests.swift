import Foundation
import XCTest
import SwiftSoup
@testable import TextSweepCore

final class BionicTransformerTests: XCTestCase {
    func testTransformsPlainParagraph() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<html><body><p>The quick brown fox.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<b>T</b>he"))
        XCTAssertTrue(result.contains("<b>qu</b>ick"))
        XCTAssertTrue(result.contains("<b>br</b>own"))
        XCTAssertTrue(result.contains("<b>f</b>ox"))
    }

    func testPreservesHTMLStructure() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<html><head><title>Test</title></head><body><h1>Title</h1><p>Text here.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<h1>"))
        XCTAssertTrue(result.contains("<p>"))
        XCTAssertTrue(result.contains("<title>"))
        XCTAssertTrue(result.contains("Test"))
    }

    func testPreservesInlineElements() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<p>This is <em>emphasized text</em> here.</p>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<em>"))
        XCTAssertTrue(result.contains("</em>"))
        XCTAssertTrue(result.contains("asized"))
    }

    func testPreservesLinks() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<p>Visit <a href=\"https://example.com\">this link</a> now.</p>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<a href=\"https://example.com\">"))
        XCTAssertTrue(result.contains("<b>li</b>nk"))
    }

    func testSkipsScriptTags() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 1)
        let html = "<html><body><script>var x = 42;</script><p>Hello world.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("var x = 42;"))
        XCTAssertFalse(result.contains("<b>var</b>"))
    }

    func testSkipsStyleTags() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 1)
        let html = "<html><body><style>body { color: red; }</style><p>Hello.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("body { color: red; }"))
        XCTAssertFalse(result.contains("<b>body</b>"))
    }

    func testHandlesNestedElements() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<div><p>First <span>nested <em>deeply nested</em> text</span> here.</p></div>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<span>"))
        XCTAssertTrue(result.contains("<em>"))
        XCTAssertTrue(result.contains("<b>ne</b>sted"))
    }

    func testHandlesEmptyBody() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig()
        let html = "<html><body></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<body>"))
    }

    func testProducesValidHTMLOutput() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2)
        let html = "<html><head><title>Book</title></head><body><p>Simple test.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        let reparsed = try SwiftSoup.parse(result)
        XCTAssertNotNil(reparsed.body())
    }

    func testTextInMultipleParagraphs() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.50, minimumWordLength: 3)
        let html = "<body><p>First paragraph here.</p><p>Second paragraph too.</p></body>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("<b>Fir</b>st"))
        XCTAssertTrue(result.contains("<b>Sec</b>ond"))
    }

    func testPreservesNonBodyText() throws {
        let transformer = BionicTransformer()
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 1)
        let html = "<html><head><title>My Book Title</title></head><body><p>Chapter text.</p></body></html>"
        let result = try transformer.transform(html: html, config: config)
        XCTAssertTrue(result.contains("My Book Title"))
    }
}
