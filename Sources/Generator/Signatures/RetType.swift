import BinaryParsing

struct RetType {
    let customModifiers: [CustomMod]
    let kind: Kind
    
    enum Kind {
        case type(Type)
        case byRef(Type)
        case void
    }
    
    init(parsing span: inout ParserSpan) throws {
        self.customModifiers = try CustomMod.lookahead(parsing: &span)
        
        var copySpan = ParserSpan(span.bytes)
        switch try UInt8(parsing: &copySpan) {
        case ElementType.byRef:
            span = copySpan
            self.kind = .byRef(try Type(parsing: &span))
        case ElementType.void:
            span = copySpan
            self.kind = .void
        default:
            self.kind = .type(try Type(parsing: &span))
        }
    }
}
