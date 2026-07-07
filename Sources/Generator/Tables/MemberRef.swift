import BinaryParsing

enum MemberRefError: Error {
    case missingClass
}

struct MemberRef {
    private let file: MetadataFile
    private let rowIndex: Index
    
    private let classIndex: CodedIndex<MemberRefParent.Tag>
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    
    var `class`: MemberRefParent {
        get throws {
            try .init(in: file, at: classIndex)
        }
    }
    
    var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    var signature: MethodDefSig {
        get throws {
            try .init(in: file, at: signatureIndex)
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .memberRef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        guard let classIndex = try CodedIndex<MemberRefParent.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.memberRefParent
        ) else {
            throw MemberRefError.missingClass
        }
        self.classIndex = classIndex
        
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .memberRef, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
