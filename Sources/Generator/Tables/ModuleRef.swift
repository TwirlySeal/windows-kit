import BinaryParsing

struct ModuleRef {
    private let metadata: MetadataDB
    
    private let nameIndex: UInt32
    
    var name: String {
        get throws { try metadata.string(at: Int(nameIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        self.nameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .moduleRef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
