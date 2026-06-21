import BinaryParsing

struct TypeRef {
    private let metadata: MetadataDB
    
    private let resolutionScopeIndex: CodedIndex<ResolutionScope.Tag>?
    private let typeNameIndex: UInt32
    private let typeNamespaceIndex: UInt32
    
    var name: String {
        get throws { try metadata.string(at: Int(typeNameIndex)) }
    }
    
    var namespace: String {
        get throws { try metadata.string(at: Int(typeNamespaceIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        let resolutionScopeValue = try UInt32(
            parsingLittleEndian: &span,
            byteCount: Int(metadata.codedIndexSizes.resolutionScope)
        )
        self.resolutionScopeIndex = try CodedIndex<ResolutionScope.Tag>(rawValue: Int(resolutionScopeValue))
        self.typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .typeRef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
