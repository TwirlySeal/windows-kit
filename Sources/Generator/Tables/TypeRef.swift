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
                try ResolutionScope(in: metadata, at: index)
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
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        self.resolutionScopeIndex = try CodedIndex<ResolutionScope.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.resolutionScope
        )
        self.typeNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeRef, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
