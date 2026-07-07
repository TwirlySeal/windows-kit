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
        get throws { try TypeDef(in: metadata, at: classIndex) }
    }
    
    var interface: TypeDefOrRef {
        get throws { try TypeDefOrRef(in: metadata, at: interfaceIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .interfaceImpl,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        index: Index
    ) throws -> Range<Index> {
        try metadata.equalRange(in: .interfaceImpl) { rowIndex in
            try InterfaceImpl(in: metadata, at: rowIndex)
                .classIndex
                .compare(to: index)
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
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
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .interfaceImpl, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
