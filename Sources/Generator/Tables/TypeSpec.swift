import BinaryParsing

struct TypeSpec {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let signatureIndex: HeapIndex
    
    var type: Type {
        get throws { try .init(in: metadata, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .typeSpec,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        self.signatureIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeSpec, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
