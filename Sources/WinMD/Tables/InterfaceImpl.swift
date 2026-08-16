import BinaryParsing

enum InterfaceImplError: Error {
    case missingClass
    case missingInterface
}

public struct InterfaceImpl {
    private let file: MetadataFile
    private let rowIndex: Index
    
    private let classIndex: Index
    private let interfaceIndex: CodedIndex<TypeDefOrRef.Tag>
    
    var `class`: TypeDef {
        get throws { try TypeDef(in: file, at: classIndex) }
    }
    
    public var interface: TypeDefOrRef {
        get throws { try TypeDefOrRef(in: file, at: interfaceIndex) }
    }
    
    public var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.rowRange(
                tag: .interfaceImpl,
                forParent: self.rowIndex,
                in: file
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    static func rowRange(
        forOwner index: Index,
        in file: MetadataFile
    ) throws -> Range<Index> {
        try file.equalRange(searchingTable: .interfaceImpl) { rowIndex in
            try InterfaceImpl(in: file, at: rowIndex)
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
