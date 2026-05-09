public struct BionicConfig: Equatable {
    public var fixationRatio: Double
    public var minimumWordLength: Int
    public var skipStopWords: Bool

    public init(
        fixationRatio: Double = 0.33,
        minimumWordLength: Int = 3,
        skipStopWords: Bool = false
    ) {
        self.fixationRatio = fixationRatio
        self.minimumWordLength = minimumWordLength
        self.skipStopWords = skipStopWords
    }

    public static let `default` = BionicConfig()
}
