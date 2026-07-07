import BinaryParsing

enum MethodDefError: Error {
    case invalidImplFlags
    case invalidFlags
    case missingParamList
}

struct MethodDef {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    private let rva: UInt32
    let implFlags: MethodImplAttributes
    let flags: MethodAttributes
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    private let paramListIndex: Index
    
    var name: String {
        get throws { try metadata.string(at: nameIndex) }
    }
    
    var signature: MethodDefSig {
        get throws { try .init(in: metadata, at: signatureIndex) }
    }
    
    var params: [Param] {
        get throws {
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: paramListIndex,
                currentTable: .methodDef,
                linkedTable: .param
            ) { rowIndex in
                try Self(in: metadata, at: rowIndex).paramListIndex
            }
            
            return try range.map { index in
                try Param(in: metadata, at: index)
            }
        }
    }
    
    var implMap: ImplMap? {
        get throws {
            try ImplMap.equalRange(in: metadata, tag: .methodDef, index: self.rowIndex)
                .first
                .map { index in
                    try ImplMap(in: metadata, at: index)
                }
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .methodDef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
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
        
        self.nameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.blobSize)
        
        guard let paramListIndex = try Index(parsing: &span, size: metadata.indexSizes.param) else {
            throw MethodDefError.missingParamList
        }
        self.paramListIndex = paramListIndex
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .methodDef, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
