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
        get throws { try .init(metadata: metadata, rowIndex: parentIndex) }
    }
    
    func compareParentIndex(index: Index) -> Ordering {
        parentIndex.compare(to: index)
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        self.packingSize = try UInt16(parsingLittleEndian: &span)
        self.classSize = try UInt32(parsingLittleEndian: &span)
        
        guard let parentIndex = try Index(parsing: &span, size: metadata.indexSizes.typeDef) else {
            throw ClassLayoutError.missingParent
        }
        self.parentIndex = parentIndex
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .classLayout, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
