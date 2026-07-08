import BinaryParsing

enum InterfaceImplError: Error {
    case missingClass
    case missingInterface
}

struct InterfaceImpl {
    private let file: MetadataFile
    private let rowIndex: Index
    
    private let classIndex: Index
    private let interfaceIndex: CodedIndex<TypeDefOrRef.Tag>
    
    var `class`: TypeDef {
        get throws { try TypeDef(in: file, at: classIndex) }
    }
    
    var interface: TypeDefOrRef {
        get throws { try TypeDefOrRef(in: file, at: interfaceIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .interfaceImpl,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    static func equalRange(
        in metadata: MetadataFile,
        index: Index
    ) throws -> Range<Index> {
        try metadata.equalRange(in: .interfaceImpl) { rowIndex in
            try InterfaceImpl(in: metadata, at: rowIndex)
                .classIndex
                .compare(to: index)
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        guard let classIndex = try Index(parsing: &span, size: file.indexSizes.typeDef) else {
            throw InterfaceImplError.missingClass
        }
        self.classIndex = classIndex
        
        guard let interfaceIndex = try CodedIndex<TypeDefOrRef.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.typeDefOrRef
        ) else {
            throw InterfaceImplError.missingInterface
        }
        self.interfaceIndex = interfaceIndex
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .interfaceImpl, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
