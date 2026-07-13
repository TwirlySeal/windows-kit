import BinaryParsing

struct ParamToken {
    let customModifiers: [CustomMod]
    let kind: Kind
    let type: Type
    
    enum Kind {
        case normal
        case byRef
    }
    
    init(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span)
        
        var copySpan = ParserSpan(span.bytes)
        switch try UInt8(parsing: &copySpan) {
        case ElementType.byRef:
            span = copySpan
            self.kind = .byRef
        default:
            self.kind = .normal
        }
        
        self.type = try Type(parsing: &span, in: file)
    }
}
