import BinaryParsing

struct MethodDef {
    private let metadata: MetadataDB
    private let rowIndex: Int
    
    private let rva: UInt32
    let implFlags: MethodImplAttributes
    let flags: MethodAttributes
    private let nameIndex: UInt32
    private let signatureIndex: UInt32
    private let paramListIndex: UInt32
    
    enum MethodDefError: Error {
        case invalidImplFlags
        case invalidFlags
    }
    
    var name: String {
        get throws { try metadata.string(at: Int(nameIndex)) }
    }
    
    var params: some Sequence<Param> {
        get throws {
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: Int(paramListIndex),
                currentTable: .methodDef,
                linkedTable: .param
            ) { nextRowIndex in
                Int(try Self(metadata: metadata, rowIndex: nextRowIndex).paramListIndex)
            }
            
            return try range.lazy.map { index in
                try Param(metadata: self.metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan, rowIndex: Int) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        self.rva = try UInt32(parsingLittleEndian: &span)
        
        guard let implFlags = MethodImplAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw MethodDefError.invalidImplFlags
        }
        self.implFlags = implFlags
        
        guard let flags = MethodAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw MethodDefError.invalidFlags
        }
        self.flags = flags
        
        self.nameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        self.signatureIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
        self.paramListIndex = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.param))
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .methodDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span, rowIndex: rowIndex)
        }
    }
}
