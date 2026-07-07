import BinaryParsing

enum GenericParamError: Error {
    case invalidFlags
    case missingOwner
}

struct GenericParam {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
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
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .genericParam,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        tag: TypeOrMethodDef.Tag,
        index: Index
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<TypeOrMethodDef.Tag>(tag: tag, index: index)
        
        return try metadata.equalRange(in: .genericParam) { rowIndex in
            try GenericParam(metadata: metadata, rowIndex: rowIndex)
                .ownerIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
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
            try Self(metadata: metadata, span: &span, rowIndex)
        }
    }
}
