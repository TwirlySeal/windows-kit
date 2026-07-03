import BinaryParsing

struct TypeRef {
    private let metadata: MetadataDB
    
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
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        self.resolutionScopeIndex = try CodedIndex<ResolutionScope.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.resolutionScope
        )
        self.typeNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeRef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
