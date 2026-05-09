public enum ConversionError: Error, Equatable {
    case notAnEPUB
    case missingContainerXML
    case missingOPF
    case invalidHTML(String)
    case zipError(reason: String)
    case fileNotFound(String)
}
