import BinaryParsing

struct ImplMap {
    private let metadata: MetadataDB
    
    let mappingFlags: PInvokeAttributes
    private let memberForwardedIndex: CodedIndex<MemberForwarded.Tag>
    private let importNameIndex: UInt32
    private let importScopeIndex: Index
    
    var memberForwarded: MemberForwarded {
        get throws { try .init(metadata: metadata, index: memberForwardedIndex) }
    }
    
    var importName: String {
        get throws { try metadata.string(at: Int(importNameIndex)) }
    }
    
    var importScope: ModuleRef {
        get throws { try .init(metadata: metadata, rowIndex: importScopeIndex) }
    }
    
    func compareMemberForwardedIndex(index: Index) -> Ordering {
        memberForwardedIndex.index.compare(to: index)
    }
    
    enum ImplMapError: Error {
        case invalidFlags
        case missingMemberForwarded
        case missingImportScope
        case invalidMemberForwarded
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard let mappingFlags = PInvokeAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw ImplMapError.invalidFlags
        }
        self.mappingFlags = mappingFlags
        
        let memberForwardedValue = try UInt32(
            parsingLittleEndian: &span,
            byteCount: Int(metadata.codedIndexSizes.memberForwarded)
        )
        guard let memberForwardedIndex = try CodedIndex<MemberForwarded.Tag>(rawValue: Int(memberForwardedValue)) else {
            throw ImplMapError.missingMemberForwarded
        }
        guard memberForwardedIndex.tag == .methodDef else {
            throw ImplMapError.invalidMemberForwarded
        }
        self.memberForwardedIndex = memberForwardedIndex
        
        self.importNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        
        let importScopeValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.moduleRef))
        guard let importScopeIndex = Index(rawValue: importScopeValue) else {
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
