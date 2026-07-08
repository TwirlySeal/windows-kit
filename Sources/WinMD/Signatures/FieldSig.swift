import BinaryParsing

struct FieldSig {
    let customModifiers: [CustomMod]
    let type: Type
    
    private init(parsing span: inout ParserSpan) throws {
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span)
        self.type = try Type(parsing: &span)
    }
    
    init(in file: MetadataFile, at offset: HeapIndex) throws {
        self = try file.withBlobSpan(at: offset) { span in
            try Self(parsing: &span)
        }
    }
}
