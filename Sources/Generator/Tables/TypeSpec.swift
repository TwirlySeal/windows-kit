import BinaryParsing

struct TypeSpec {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let signatureIndex: HeapIndex
    
    var type: Type {
        get throws { try .init(metadata: metadata, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .typeSpec,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        self.signatureIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeSpec, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span, rowIndex)
        }
    }
}
