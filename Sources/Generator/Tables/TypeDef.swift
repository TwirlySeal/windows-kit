import BinaryParsing

struct TypeDef {
    private let metadata: MetadataDB
    let flags: TypeAttributes
    let typeName: String
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard
            let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span))
        else {
            throw ParsingError()
        }
        self.flags = flags
        let typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.ranges.heapSizes.stringSize)
        self.typeName = try metadata.string(at: Int(typeNameIndex))
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
