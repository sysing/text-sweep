import Foundation

public protocol Tokenizing {
    func applyBionicReading(to text: String) -> String
}

public final class TextTokenizer: Tokenizing {
    public let config: BionicConfig

    public init(config: BionicConfig = .default) {
        self.config = config
    }

    private let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
        "being", "have", "has", "had", "do", "does", "did", "will", "would",
        "could", "should", "may", "might", "can", "shall", "i", "you", "he",
        "she", "it", "we", "they", "me", "him", "her", "us", "them", "my",
        "your", "his", "its", "our", "their", "this", "that", "these", "those",
        "not", "no", "if", "so", "as", "than", "too", "very", "just", "about",
        "into", "over", "under", "after", "before", "between", "through",
    ]

    public func applyBionicReading(to text: String) -> String {
        var result = ""
        var currentToken = ""

        for char in text {
            if char.isWhitespace || char.isNewline {
                if !currentToken.isEmpty {
                    result += processToken(currentToken)
                    currentToken = ""
                }
                result.append(char)
            } else {
                currentToken.append(char)
            }
        }

        if !currentToken.isEmpty {
            result += processToken(currentToken)
        }

        return result
    }

    private func processToken(_ token: String) -> String {
        guard let (leading, word, trailing) = splitPunctuation(token), !word.isEmpty else {
            return token
        }

        guard word.contains(where: { $0.isLetter }) else {
            return token
        }

        guard word.count >= config.minimumWordLength else {
            return token
        }

        if config.skipStopWords, isStopWord(word) {
            return token
        }

        let calculated = Int((Double(word.count) * config.fixationRatio).rounded(.up))
        let fixation = min(calculated, word.count - 1)
        guard fixation > 0 else {
            return token
        }

        let prefix = String(word.prefix(fixation))
        let remainder = String(word.suffix(word.count - fixation))

        return leading + "<b>" + prefix + "</b>" + remainder + trailing
    }

    private func splitPunctuation(_ token: String) -> (leading: String, word: String, trailing: String)? {
        var start = token.startIndex
        while start < token.endIndex, !isWordChar(token[start]) {
            start = token.index(after: start)
        }

        var end = token.endIndex
        while end > start, !isWordChar(token[token.index(before: end)]) {
            end = token.index(before: end)
        }

        let leading = String(token[token.startIndex..<start])
        let word = String(token[start..<end])
        let trailing = String(token[end..<token.endIndex])

        return (leading, word, trailing)
    }

    private func isWordChar(_ char: Character) -> Bool {
        char.isLetter || char.isNumber || char == "'" || char == "-" || char == "\u{2019}"
    }

    private func isStopWord(_ word: String) -> Bool {
        stopWords.contains(word.lowercased())
    }
}
