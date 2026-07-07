import BinaryParsing

enum MemberRefError: Error {
    case missingClass
}

struct MemberRef {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let classIndex: CodedIndex<MemberRefParent.Tag>
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    
    var `class`: MemberRefParent {
        get throws {
            try .init(metadata: metadata, index: classIndex)
        }
    }
    
    var name: String {
        get throws { try metadata.string(at: nameIndex) }
    }
    
    var signature: MethodDefSig {
        get throws {
            try .init(metadata: metadata, at: signatureIndex)
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .memberRef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        guard let classIndex = try CodedIndex<MemberRefParent.Tag>(
            parsing: &span,
            size: metadata.codedIndexSizes.memberRefParent
        ) else {
            throw MemberRefError.missingClass
        }
        self.classIndex = classIndex
        
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .memberRef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, parsing: &span, rowIndex)
        }
    }
}
