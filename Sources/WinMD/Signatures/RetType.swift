import BinaryParsing

public struct RetType {
    public let customModifiers: [CustomMod]
    public let kind: Kind
    
    public enum Kind {
        case type(Type)
        case byRef(Type)
        case void
    }
    
    init(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span, in: file)
        
        var copySpan = ParserSpan(span.bytes)
        switch try UInt8(parsing: &copySpan) {
        case ElementType.byRef:
            span = copySpan
            self.kind = .byRef(try Type(parsing: &span, in: file))
        case ElementType.void:
            span = copySpan
            self.kind = .void
        default:
            self.kind = .type(try Type(parsing: &span, in: file))
        }
    }
}
