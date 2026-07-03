import BinaryParsing

enum GenericParamError: Error {
    case invalidFlags
    case missingOwner
}

struct GenericParam {
    private let metadata: MetadataDB
    
    let number: UInt16
    let flags: GenericParamAttributes
    private let ownerIndex: CodedIndex<TypeOrMethodDef.Tag>
    private let nameIndex: HeapIndex
    
    var owner: TypeOrMethodDef {
        get throws {
            try .init(metadata: metadata, index: ownerIndex)
        }
    }
    
    var name: String {
        get throws {
            try metadata.string(at: nameIndex)
        }
    }
    
    func compareOwnerIndex(index: Index) -> Ordering {
        ownerIndex.index.compare(to: index)
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        self.number = try UInt16(parsingLittleEndian: &span)
        
        guard let flags = GenericParamAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw GenericParamError.invalidFlags
        }
        self.flags = flags
        
        guard let ownerIndex = try CodedIndex<TypeOrMethodDef.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.typeOrMethodDef
        ) else {
            throw GenericParamError.missingOwner
        }
        self.ownerIndex = ownerIndex
        
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .genericParam, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
