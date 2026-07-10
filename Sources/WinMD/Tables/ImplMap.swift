import BinaryParsing

enum ImplMapError: Error {
    case invalidFlags
    case missingMemberForwarded
    case missingImportScope
}

struct ImplMap {
    private let file: MetadataFile
    
    let mappingFlags: PInvokeAttributes
    private let memberForwardedIndex: CodedIndex<MemberForwarded.Tag>
    private let importNameIndex: HeapIndex
    private let importScopeIndex: Index
    
    var memberForwarded: MemberForwarded {
        get throws { try .init(in: file, at: memberForwardedIndex) }
    }
    
    var importName: String {
        get throws { try file.string(at: importNameIndex) }
    }
    
    var importScope: ModuleRef {
        get throws { try .init(in: file, at: importScopeIndex) }
    }
    
    static func rowRange(
        tag: MemberForwarded.Tag,
        forOwner ownerIndex: Index,
        in file: MetadataFile
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<MemberForwarded.Tag>(tag: tag, index: ownerIndex)
        
        return try file.equalRange(searchingTable: .implMap) { rowIndex in
            try ImplMap(in: file, at: rowIndex)
                .memberForwardedIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        
        guard let mappingFlags = PInvokeAttributes(
            rawValue: try UInt16(parsingLittleEndian: &span)
        ) else {
            throw ImplMapError.invalidFlags
        }
        self.mappingFlags = mappingFlags
        
        guard let memberForwardedIndex = try CodedIndex<MemberForwarded.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.memberForwarded
        ) else {
            throw ImplMapError.missingMemberForwarded
        }
        self.memberForwardedIndex = memberForwardedIndex
        
        self.importNameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        
        guard let importScopeIndex = try Index(parsing: &span, size: file.indexSizes.moduleRef) else {
            throw ImplMapError.missingImportScope
        }
        self.importScopeIndex = importScopeIndex
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .implMap, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
