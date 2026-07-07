import BinaryParsing

enum InterfaceImplError: Error {
    case missingClass
    case missingInterface
}

struct InterfaceImpl {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let classIndex: Index
    private let interfaceIndex: CodedIndex<TypeDefOrRef.Tag>
    
    var `class`: TypeDef {
        get throws { try TypeDef(metadata: metadata, rowIndex: classIndex) }
    }
    
    var interface: TypeDefOrRef {
        get throws { try TypeDefOrRef(metadata: metadata, index: interfaceIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .interfaceImpl,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        index: Index
    ) throws -> Range<Index> {
        try metadata.equalRange(in: .interfaceImpl) { rowIndex in
            try InterfaceImpl(metadata: metadata, rowIndex: rowIndex)
                .classIndex
                .compare(to: index)
        }
    }
    
    private init(metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        guard let classIndex = try Index(parsing: &span, size: metadata.indexSizes.typeDef) else {
            throw InterfaceImplError.missingClass
        }
        self.classIndex = classIndex
        
        guard let interfaceIndex = try CodedIndex<TypeDefOrRef.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.typeDefOrRef
        ) else {
            throw InterfaceImplError.missingInterface
        }
        self.interfaceIndex = interfaceIndex
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .interfaceImpl, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, parsing: &span, rowIndex)
        }
    }
}
