import BinaryParsing

enum ImplMapError: Error {
    case invalidFlags
    case missingMemberForwarded
    case missingImportScope
}

struct ImplMap {
    private let metadata: MetadataDB
    
    let mappingFlags: PInvokeAttributes
    private let memberForwardedIndex: CodedIndex<MemberForwarded.Tag>
    private let importNameIndex: HeapIndex
    private let importScopeIndex: Index
    
    var memberForwarded: MemberForwarded {
        get throws { try .init(metadata: metadata, index: memberForwardedIndex) }
    }
    
    var importName: String {
        get throws { try metadata.string(at: importNameIndex) }
    }
    
    var importScope: ModuleRef {
        get throws { try .init(metadata: metadata, rowIndex: importScopeIndex) }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        tag: MemberForwarded.Tag,
        index: Index
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<MemberForwarded.Tag>(tag: tag, index: index)
        
        return try metadata.equalRange(in: .implMap) { rowIndex in
            try ImplMap(metadata: metadata, rowIndex: rowIndex)
                .memberForwardedIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard let mappingFlags = PInvokeAttributes(
            rawValue: try UInt16(parsingLittleEndian: &span)
        ) else {
            throw ImplMapError.invalidFlags
        }
        self.mappingFlags = mappingFlags
        
        guard let memberForwardedIndex = try CodedIndex<MemberForwarded.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.memberForwarded
        ) else {
            throw ImplMapError.missingMemberForwarded
        }
        self.memberForwardedIndex = memberForwardedIndex
        
        self.importNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        
        guard let importScopeIndex = try Index(parsing: &span, size: metadata.indexSizes.moduleRef) else {
            throw ImplMapError.missingImportScope
        }
        self.importScopeIndex = importScopeIndex
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .implMap, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
