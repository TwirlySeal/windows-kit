import BinaryParsing

struct Param {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    let flags: ParamAttributes
    let sequence: UInt16
    private let nameIndex: HeapIndex
    
    var name: String {
        get throws { try metadata.string(at: nameIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .param,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        self.flags = ParamAttributes(rawValue: try UInt16(parsingLittleEndian: &span))
        self.sequence = try UInt16(parsingLittleEndian: &span)
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .param, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
