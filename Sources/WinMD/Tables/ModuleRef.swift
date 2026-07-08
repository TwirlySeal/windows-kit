import BinaryParsing

struct ModuleRef {
    private let file: MetadataFile
    
    private let nameIndex: HeapIndex
    
    var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .moduleRef, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
