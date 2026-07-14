import BinaryParsing

enum FieldSigError: Error {
    case invalidMagicNumber
}

public struct FieldSig {
    public let customModifiers: [CustomMod]
    public let type: Type
    
    private init(parsing span: inout ParserSpan, in file: MetadataFile) throws {
        guard try UInt8(parsing: &span) == 0x6 else {
            throw FieldSigError.invalidMagicNumber
        }
        self.customModifiers = try CustomMod.parseZeroOrMore(from: &span, in: file)
        self.type = try Type(parsing: &span, in: file)
    }
    
    init(in file: MetadataFile, at offset: HeapIndex) throws {
        self = try file.withBlobSpan(at: offset) { span in
            try Self(parsing: &span, in: file)
        }
    }
}
