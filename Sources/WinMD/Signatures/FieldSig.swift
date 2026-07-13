import BinaryParsing

public struct FieldSig {
    let customModifiers: [CustomMod]
    public let type: Type
    
    private init(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span)
        self.type = try Type(parsing: &span, in: file)
    }
    
    init(in file: MetadataFile, at offset: HeapIndex) throws {
        self = try file.withBlobSpan(at: offset) { span in
            try Self(parsing: &span, in: file)
        }
    }
}
