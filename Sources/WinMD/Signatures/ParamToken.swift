import BinaryParsing

public struct ParamToken {
    public let customModifiers: [CustomMod]
    public let kind: Kind
    public let type: Type
    
    public enum Kind {
        case normal
        case byRef
    }
    
    init(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span, in: file)
        
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
