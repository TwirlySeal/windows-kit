import BinaryParsing

enum CustomAttributeError: Error {
    case missingParent
    case missingType
    case noHasThis
    case nonVoidReturnType
}

struct CustomAttribute {
    private let metadata: MetadataDB
    
    private let parentIndex: CodedIndex<HasCustomAttribute.Tag>
    private let typeIndex: CodedIndex<CustomAttributeType.Tag>
    private let valueIndex: HeapIndex
    
    var parent: HasCustomAttribute {
        get throws {
            try .init(in: metadata, at: parentIndex)
        }
    }
    
    var type: CustomAttributeType {
        get throws {
            try .init(in: metadata, at: typeIndex)
        }
    }
    
    var value: CustomAttrib {
        get throws {
            let methodDefSig = switch try type {
            case .methodDef(let methodDef):
                try methodDef.signature
            case .memberRef(let memberRef):
                try memberRef.signature
            }
            
            guard methodDefSig.header.flags.contains(.hasThis) else {
                throw CustomAttributeError.noHasThis
            }
            guard case .void = methodDefSig.returnType.kind else {
                throw CustomAttributeError.nonVoidReturnType
            }
            
            return try .init(in: metadata, at: valueIndex, params: methodDefSig.params)
        }
    }
    
    static func equalRange(
        in metadata: MetadataDB,
        tag: HasCustomAttribute.Tag,
        index: Index
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<HasCustomAttribute.Tag>(tag: tag, index: index)
        
        return try metadata.equalRange(in: .customAttribute) { rowIndex in
            try CustomAttribute(in: metadata, at: rowIndex)
                .parentIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard let parentIndex = try CodedIndex<HasCustomAttribute.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.hasCustomAttribute
        ) else {
            throw CustomAttributeError.missingParent
        }
        self.parentIndex = parentIndex
        
        guard let typeIndex = try CodedIndex<CustomAttributeType.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.customAttributeType
        ) else {
            throw CustomAttributeError.missingType
        }
        self.typeIndex = typeIndex
        
        self.valueIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .customAttribute, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span)
        }
    }
}
