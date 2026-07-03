import BinaryParsing

enum CustomAttributeError: Error {
    case missingParent
    case missingType
}

struct CustomAttribute {
    private let metadata: MetadataDB
    
    private let parentIndex: CodedIndex<HasCustomAttribute.Tag>
    private let typeIndex: CodedIndex<CustomAttributeType.Tag>
    private let valueIndex: UInt32
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        let parentValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.hasCustomAttribute))
        guard let parentIndex = try CodedIndex<HasCustomAttribute.Tag>(rawValue: Int(parentValue)) else {
            throw CustomAttributeError.missingParent
        }
        self.parentIndex = parentIndex
        
        let typeValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.customAttributeType))
        guard let typeIndex = try CodedIndex<CustomAttributeType.Tag>(rawValue: Int(typeValue)) else {
            throw CustomAttributeError.missingType
        }
        self.typeIndex = typeIndex
        
        self.valueIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .customAttribute, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
