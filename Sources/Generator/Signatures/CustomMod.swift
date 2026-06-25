import BinaryParsing

struct CustomMod {
    let required: Bool
    let typeIndex: CodedIndex<TypeDefOrRef.Tag>
    
    enum CustomModError: Error {
        case nullTypeIndex
    }
    
    init?(span: inout ParserSpan) throws {
        switch try UInt8(parsing: &span) {
        case ElementType.cmodOpt:
            self.required = false
        case ElementType.cmodReqd:
            self.required = true
        default:
            return nil
        }
        
        let rawValue = try MetadataDB.parseCompressedUnsignedInteger(span: &span)
        guard let typeIndex = try CodedIndex<TypeDefOrRef.Tag>(rawValue: Int(rawValue)) else {
            throw CustomModError.nullTypeIndex
        }
        self.typeIndex = typeIndex
    }
    
    /// Parse an unknown number of custom modifiers with lookahead
    static func lookahead(parsing span: inout ParserSpan) throws -> [Self] {
        // It is not known how many custom modifiers there are,
        // so a copy of the span is made to try parsing one and the state change
        // is committed if successful
        var customMods = [Self]()
        while true {
            var copySpan = ParserSpan(span.bytes)
            guard let customMod = try CustomMod(span: &copySpan) else {
                break
            }
            customMods.append(customMod)
            span = copySpan
        }
        return customMods
    }
}
