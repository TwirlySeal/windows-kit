import BinaryParsing

enum MemberRefError: Error {
    case missingClass
}

struct MemberRef {
    private let metadata: MetadataDB
    
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
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
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
            try Self(metadata: metadata, span: &span)
        }
    }
}
