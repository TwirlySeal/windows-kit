import BinaryParsing

enum GenericParamError: Error {
    case invalidFlags
    case missingOwner
}

struct GenericParam {
    private let file: MetadataFile
    private let rowIndex: Index
    
    let number: UInt16
    let flags: GenericParamAttributes
    private let ownerIndex: CodedIndex<TypeOrMethodDef.Tag>
    private let nameIndex: HeapIndex
    
    var owner: TypeOrMethodDef {
        get throws {
            try .init(in: file, at: ownerIndex)
        }
    }
    
    var name: String {
        get throws {
            try file.string(at: nameIndex)
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .genericParam,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    static func equalRange(
        in metadata: MetadataFile,
        tag: TypeOrMethodDef.Tag,
        index: Index
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<TypeOrMethodDef.Tag>(tag: tag, index: index)
        
        return try metadata.equalRange(in: .genericParam) { rowIndex in
            try GenericParam(in: metadata, at: rowIndex)
                .ownerIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        self.number = try UInt16(parsingLittleEndian: &span)
        
        guard let flags = GenericParamAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw GenericParamError.invalidFlags
        }
        self.flags = flags
        
        guard let ownerIndex = try CodedIndex<TypeOrMethodDef.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.typeOrMethodDef
        ) else {
            throw GenericParamError.missingOwner
        }
        self.ownerIndex = ownerIndex
        
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .genericParam, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
