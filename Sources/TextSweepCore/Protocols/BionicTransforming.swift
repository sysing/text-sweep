public protocol BionicTransforming {
    func transform(html: String, config: BionicConfig) throws -> String
}
