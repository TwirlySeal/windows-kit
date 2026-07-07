import BinaryParsing

enum ClassLayoutError: Error {
    case missingParent
}

struct ClassLayout {
    private let metadata: MetadataDB
    
    let packingSize: UInt16
    let classSize: UInt32
    private let parentIndex: Index
    
    var parent: TypeDef {
        get throws { try .init(in: metadata, at: parentIndex) }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        index: Index
    ) throws -> Range<Index> {
        try metadata.equalRange(in: .classLayout) { rowIndex in
            try ClassLayout(in: metadata, at: rowIndex)
                .parentIndex
                .compare(to: index)
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan) throws {
        self.metadata = metadata
        self.packingSize = try UInt16(parsingLittleEndian: &span)
        self.classSize = try UInt32(parsingLittleEndian: &span)
        
        guard let parentIndex = try Index(parsing: &span, size: metadata.indexSizes.typeDef) else {
            throw ClassLayoutError.missingParent
        }
        self.parentIndex = parentIndex
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .classLayout, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span)
        }
    }
}
