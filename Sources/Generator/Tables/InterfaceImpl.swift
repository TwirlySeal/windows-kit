import BinaryParsing

enum InterfaceImplError: Error {
    case missingClass
    case missingInterface
}

struct InterfaceImpl {
    private let metadata: MetadataDB
    
    private let classIndex: Index
    private let interfaceIndex: CodedIndex<TypeDefOrRef.Tag>
    
    var `class`: TypeDef {
        get throws { try TypeDef(metadata: metadata, rowIndex: classIndex) }
    }
    
    var interface: TypeDefOrRef {
        get throws { try TypeDefOrRef(metadata: metadata, index: interfaceIndex) }
    }
    
    func compareClassIndex(index: Index) -> Ordering {
        classIndex.compare(to: index)
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
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
            try Self(metadata: metadata, span: &span)
        }
    }
}
