import XCTest
@testable import TextSweepCore

final class TextTokenizerTests: XCTestCase {
    func testBoldsSimpleSentence() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.33, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "The quick brown fox jumps.")
        XCTAssertEqual(result, "<b>T</b>he <b>qu</b>ick <b>br</b>own <b>f</b>ox <b>ju</b>mps.")
    }

    func testPreservesLeadingPunctuation() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.50, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "\u{201C}Hello\u{201D}")
        XCTAssertTrue(result.contains("<b>Hel</b>lo"))
    }

    func testPreservesTrailingPunctuation() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.33, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "Hello, world!")
        XCTAssertEqual(result, "<b>He</b>llo, <b>wo</b>rld!")
    }

    func testHandlesEmptyString() {
        let tokenizer = TextTokenizer()
        let result = tokenizer.applyBionicReading(to: "")
        XCTAssertEqual(result, "")
    }

    func testHandlesWhitespaceOnly() {
        let tokenizer = TextTokenizer()
        let result = tokenizer.applyBionicReading(to: "   \n  \t  ")
        XCTAssertEqual(result, "   \n  \t  ")
    }

    func testRespectsMinimumWordLength() {
        let config = BionicConfig(fixationRatio: 0.50, minimumWordLength: 4)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "a cat dog run fast enough")
        XCTAssertEqual(result, "a cat dog run <b>fa</b>st <b>eno</b>ugh")
    }

    func testSkipsStopWordsWhenEnabled() {
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2, skipStopWords: true)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "the quick brown fox")
        XCTAssertEqual(result, "the <b>qu</b>ick <b>br</b>own <b>f</b>ox")
    }

    func testDoesNotSkipStopWordsWhenDisabled() {
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 2, skipStopWords: false)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "the quick brown fox")
        XCTAssertEqual(result, "<b>t</b>he <b>qu</b>ick <b>br</b>own <b>f</b>ox")
    }

    func testHandlesApostrophes() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.50, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "don't can't it's")
        XCTAssertEqual(result, "<b>don</b>'t <b>can</b>'t <b>it</b>'s")
    }

    func testHandlesSmartApostrophe() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.50, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "don\u{2019}t can\u{2019}t")
        XCTAssertEqual(result, "<b>don</b>\u{2019}t <b>can</b>\u{2019}t")
    }

    func testHandlesHyphenatedWords() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.33, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "well-known state-of-the-art")
        XCTAssertEqual(result, "<b>well</b>-known <b>state-</b>of-the-art")
    }

    func testHandlesNumbers() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.50, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "There are 42 apples.")
        XCTAssertEqual(result, "<b>The</b>re <b>ar</b>e 42 <b>app</b>les.")
    }

    func testPreservesNewlines() {
        let tokenizer = TextTokenizer(config: BionicConfig(fixationRatio: 0.33, minimumWordLength: 2))
        let result = tokenizer.applyBionicReading(to: "Line one.\nLine two.")
        XCTAssertTrue(result.contains("\n"))
    }

    func testHandlesSingleCharacterWord() {
        let config = BionicConfig(fixationRatio: 0.33, minimumWordLength: 1)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "I am here.")
        XCTAssertEqual(result, "I <b>a</b>m <b>he</b>re.")
    }

    func testAllCharactersBoldWithHighRatio() {
        let config = BionicConfig(fixationRatio: 0.99, minimumWordLength: 2)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "Hi")
        let boldCount = result.components(separatedBy: "<b>").count - 1
        XCTAssertEqual(boldCount, 1)
        XCTAssertEqual(result, "<b>H</b>i")
    }

    func testFixationIsAtLeastOne() {
        let config = BionicConfig(fixationRatio: 0.01, minimumWordLength: 2)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "cat")
        XCTAssertEqual(result, "<b>c</b>at")
    }

    func testFixationDoesNotExceedWordLength() {
        let config = BionicConfig(fixationRatio: 0.99, minimumWordLength: 3)
        let tokenizer = TextTokenizer(config: config)
        let result = tokenizer.applyBionicReading(to: "cat")
        XCTAssertEqual(result, "<b>ca</b>t")
    }
}
