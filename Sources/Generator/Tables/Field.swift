import BinaryParsing

enum FieldError: Error {
    case invalidFieldAttributes
}

struct Field {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    let flags: FieldAttributes
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    
    var name: String {
        get throws { try metadata.string(at: nameIndex) }
    }
    
    var signature: FieldSig {
        get throws { try .init(metadata: metadata, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .field,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        guard let flags = FieldAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw FieldError.invalidFieldAttributes
        }
        self.flags = flags
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .field, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, parsing: &span, rowIndex)
        }
    }
}
