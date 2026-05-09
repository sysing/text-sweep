import Foundation
import SwiftSoup

public final class BionicTransformer: BionicTransforming {
    public init() {}

    public func transform(html: String, config: BionicConfig) throws -> String {
        let document = try SwiftSoup.parse(html)
        let tokenizer = TextTokenizer(config: config)

        if let body = document.body() {
            try processNode(body, tokenizer: tokenizer)
        }

        document.outputSettings().syntax(syntax: OutputSettings.Syntax.xml)
        document.outputSettings().escapeMode(Entities.EscapeMode.xhtml)
        return try document.html()
    }

    private func processNode(_ node: Node, tokenizer: TextTokenizer) throws {
        if let textNode = node as? TextNode {
            let original = textNode.text()
            let transformed = tokenizer.applyBionicReading(to: original)
            if transformed != original {
                try textNode.before(transformed)
                try textNode.remove()
            }
        } else if let element = node as? Element {
            let tagName = element.tagName().lowercased()
            guard tagName != "script", tagName != "style" else {
                return
            }
            for child in element.getChildNodes() {
                try processNode(child, tokenizer: tokenizer)
            }
        }
    }
}
