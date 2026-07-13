import BinaryParsing

enum CustomAttributeError: Error {
    case missingParent
    case missingType
    case noHasThis
    case nonVoidReturnType
}

public struct CustomAttribute {
    private let file: MetadataFile
    
    private let parentIndex: CodedIndex<HasCustomAttribute.Tag>
    private let typeIndex: CodedIndex<CustomAttributeType.Tag>
    private let valueIndex: HeapIndex
    
    var parent: HasCustomAttribute {
        get throws {
            try .init(in: file, at: parentIndex)
        }
    }
    
    public var type: CustomAttributeType {
        get throws {
            try .init(in: file, at: typeIndex)
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
            
            return try .init(in: file, at: valueIndex, params: methodDefSig.params)
        }
    }
    
    static func rowRange(
        tag: HasCustomAttribute.Tag,
        forParent parentIndex: Index,
        in file: MetadataFile
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<HasCustomAttribute.Tag>(tag: tag, index: parentIndex)
        
        return try file.equalRange(searchingTable: .customAttribute) { rowIndex in
            try CustomAttribute(in: file, at: rowIndex)
                .parentIndex
                .compare(to: codedIndex)
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        
        guard let parentIndex = try CodedIndex<HasCustomAttribute.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.hasCustomAttribute
        ) else {
            throw CustomAttributeError.missingParent
        }
        self.parentIndex = parentIndex
        
        guard let typeIndex = try CodedIndex<CustomAttributeType.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.customAttributeType
        ) else {
            throw CustomAttributeError.missingType
        }
        self.typeIndex = typeIndex
        
        self.valueIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .customAttribute, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
