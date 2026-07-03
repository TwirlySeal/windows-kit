import BinaryParsing

enum CustomAttributeError: Error {
    case missingParent
    case missingType
}

struct CustomAttribute {
    private let metadata: MetadataDB
    
    private let parentIndex: CodedIndex<HasCustomAttribute.Tag>
    private let typeIndex: CodedIndex<CustomAttributeType.Tag>
    private let valueIndex: HeapIndex
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
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
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .customAttribute, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
