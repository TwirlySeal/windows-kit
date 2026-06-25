import BinaryParsing

struct TypeSpec {
    private let metadata: MetadataDB
    
    private let signatureIndex: UInt32
    
    var type: Type {
        get throws { try .init(metadata: metadata, at: Int(signatureIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        self.signatureIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeSpec, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
