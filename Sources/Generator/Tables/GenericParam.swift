import BinaryParsing

struct GenericParam {
    private let metadata: MetadataDB
    
    let number: UInt16
    let flags: GenericParamAttributes
    private let ownerIndex: CodedIndex<TypeOrMethodDef.Tag>
    private let nameIndex: UInt32
    
    enum GenericParamError: Error {
        case invalidFlags
        case missingOwner
    }
    
    var owner: TypeOrMethodDef {
        get throws {
            try .init(metadata: metadata, index: ownerIndex)
        }
    }
    
    var name: String {
        get throws {
            try metadata.string(at: Int(nameIndex))
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
        
        let ownerValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.typeOrMethodDef))
        guard let ownerIndex = try CodedIndex<TypeOrMethodDef.Tag>(rawValue: Int(ownerValue)) else {
            throw GenericParamError.missingOwner
        }
        self.ownerIndex = ownerIndex
        
        self.nameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .genericParam, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
