import SwiftUI
import TextSweepCore

struct BionicConfigViewModel {
    var fixationRatio: Double
    var minimumWordLength: Int
    var skipStopWords: Bool

    init(
        fixationRatio: Double = 0.33,
        minimumWordLength: Int = 3,
        skipStopWords: Bool = false
    ) {
        self.fixationRatio = fixationRatio
        self.minimumWordLength = minimumWordLength
        self.skipStopWords = skipStopWords
    }

    var toCoreConfig: BionicConfig {
        BionicConfig(
            fixationRatio: fixationRatio,
            minimumWordLength: minimumWordLength,
            skipStopWords: skipStopWords
        )
    }
}
