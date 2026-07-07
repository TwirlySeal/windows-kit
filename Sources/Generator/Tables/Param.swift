import BinaryParsing

struct Param {
    private let file: MetadataFile
    private let rowIndex: Index
    
    let flags: ParamAttributes
    let sequence: UInt16
    private let nameIndex: HeapIndex
    
    var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .param,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        self.flags = ParamAttributes(rawValue: try UInt16(parsingLittleEndian: &span))
        self.sequence = try UInt16(parsingLittleEndian: &span)
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .param, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
