import BinaryParsing

enum FieldError: Error {
    case invalidFieldAttributes
}

struct Field {
    private let metadata: MetadataDB
    let flags: FieldAttributes
    private let nameIndex: UInt32
    private let signatureIndex: UInt32
    
    var name: String {
        get throws { try metadata.string(at: Int(nameIndex)) }
    }
    
    var signature: FieldSig {
        get throws { try .init(metadata: metadata, at: Int(signatureIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        guard let flags = FieldAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw FieldError.invalidFieldAttributes
        }
        self.flags = flags
        self.nameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        self.signatureIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .field, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
