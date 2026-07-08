import BinaryParsing

enum ClassLayoutError: Error {
    case missingParent
}

struct ClassLayout {
    private let file: MetadataFile
    
    let packingSize: UInt16
    let classSize: UInt32
    private let parentIndex: Index
    
    var parent: TypeDef {
        get throws { try .init(in: file, at: parentIndex) }
    }
    
    static func equalRange(
        in metadata: MetadataFile,
        index: Index
    ) throws -> Range<Index> {
        try metadata.equalRange(in: .classLayout) { rowIndex in
            try ClassLayout(in: metadata, at: rowIndex)
                .parentIndex
                .compare(to: index)
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        self.packingSize = try UInt16(parsingLittleEndian: &span)
        self.classSize = try UInt32(parsingLittleEndian: &span)
        
        guard let parentIndex = try Index(parsing: &span, size: file.indexSizes.typeDef) else {
            throw ClassLayoutError.missingParent
        }
        self.parentIndex = parentIndex
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .classLayout, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
