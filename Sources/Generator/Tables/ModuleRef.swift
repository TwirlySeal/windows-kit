import BinaryParsing

struct ModuleRef {
    private let metadata: MetadataDB
    
    private let nameIndex: HeapIndex
    
    var name: String {
        get throws { try metadata.string(at: nameIndex) }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan) throws {
        self.metadata = metadata
        
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .moduleRef, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span)
        }
    }
}
