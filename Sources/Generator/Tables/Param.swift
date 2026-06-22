import BinaryParsing

struct Param {
    private let metadata: MetadataDB
    let flags: ParamAttributes
    let sequence: UInt16
    private let nameIndex: UInt32
    
    var name: String {
        get throws { try metadata.string(at: Int(nameIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        self.flags = ParamAttributes(rawValue: try UInt16(parsingLittleEndian: &span))
        self.sequence = try UInt16(parsingLittleEndian: &span)
        self.nameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .param, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
