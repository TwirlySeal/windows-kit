import BinaryParsing

struct TypeSpec {
    private let metadata: MetadataDB
    
    private let signatureIndex: UInt32
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        self.signatureIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .typeSpec, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
