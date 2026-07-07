import BinaryParsing

struct TypeRef {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let resolutionScopeIndex: CodedIndex<ResolutionScope.Tag>?
    private let typeNameIndex: HeapIndex
    private let typeNamespaceIndex: HeapIndex
    
    var resolutionScope: ResolutionScope? {
        get throws {
            try resolutionScopeIndex.map { index in
                try ResolutionScope(metadata: metadata, index: index)
            }
        }
    }
    
    var name: String {
        get throws { try metadata.string(at: typeNameIndex) }
    }
    
    var namespace: String {
        get throws { try metadata.string(at: typeNamespaceIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .typeRef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        self.resolutionScopeIndex = try CodedIndex<ResolutionScope.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.resolutionScope
        )
        self.typeNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeRef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, parsing: &span, rowIndex)
        }
    }
}
