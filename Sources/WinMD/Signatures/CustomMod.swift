import BinaryParsing

public struct CustomMod {
    private let file: MetadataFile
    
    let required: Bool
    private let typeIndex: CodedIndex<TypeDefOrRef.Tag>
    
    public var type: TypeDefOrRef {
        get throws {
            try .init(in: file, at: typeIndex)
        }
    }
    
    enum CustomModError: Error {
        case nullTypeIndex
    }
    
    init?(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        self.file = file
        switch try UInt8(parsing: &span) {
        case ElementType.cmodOpt:
            self.required = false
        case ElementType.cmodReqd:
            self.required = true
        default:
            return nil
        }
        
        let rawValue = try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        guard let typeIndex = try CodedIndex<TypeDefOrRef.Tag>(rawValue: rawValue) else {
            throw CustomModError.nullTypeIndex
        }
        self.typeIndex = typeIndex
    }
    
    /// Parse an unknown number of custom modifiers with lookahead
    static func parseZeroOrMore(from span: inout ParserSpan, in file: MetadataFile) throws -> [Self] {
        // It is not known how many custom modifiers there are,
        // so a copy of the span is made to try parsing one and the state change
        // is committed if successful
        var customMods = [Self]()
        while true {
            var copySpan = ParserSpan(span.bytes)
            guard let customMod = try CustomMod(parsing: &copySpan, in: file) else {
                break
            }
            customMods.append(customMod)
            span = copySpan
        }
        return customMods
    }
}
