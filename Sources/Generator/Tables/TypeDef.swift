import BinaryParsing

struct TypeDef {
    private let metadata: MetadataDB
    let flags: TypeAttributes
    private let typeNameIndex: UInt32
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard
            let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span))
        else {
            throw ParsingError()
        }
        self.flags = flags
        self.typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.ranges.heapSizes!.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
