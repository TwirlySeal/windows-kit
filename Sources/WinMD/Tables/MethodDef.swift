import BinaryParsing

enum MethodDefError: Error {
    case invalidImplFlags
    case invalidFlags
    case missingParamList
}

public struct MethodDef {
    private let file: MetadataFile
    private let rowIndex: Index
    
    private let rva: UInt32
    let implFlags: MethodImplAttributes
    let flags: MethodAttributes
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    private let paramListIndex: Index
    
    public var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    public var signature: MethodDefSig {
        get throws { try .init(in: file, at: signatureIndex) }
    }
    
    public var params: [Param] {
        get throws {
            let range = try file.listRowRange(
                forParentRow: self.rowIndex,
                startingChildIndex: paramListIndex,
                parentTableID: .methodDef,
                childTableID: .param
            ) { rowIndex in
                try Self(in: file, at: rowIndex).paramListIndex
            }
            
            return try range.map { index in
                try Param(in: file, at: index)
            }
        }
    }
    
    var implMap: ImplMap? {
        get throws {
            try ImplMap.rowRange(tag: .methodDef, forOwner: self.rowIndex, in: file)
                .first
                .map { index in
                    try ImplMap(in: file, at: index)
                }
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.rowRange(
                tag: .methodDef,
                forParent: self.rowIndex,
                in: file
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    var parent: MemberRefParent {
        get throws {
            let index = try TypeDef.parentOfMethod(at: self.rowIndex, in: file)
            
            return MemberRefParent.typeDef(
                try TypeDef(in: file, at: index)
            )
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
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
        
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
        
        guard let paramListIndex = try Index(parsing: &span, size: file.indexSizes.param) else {
            throw MethodDefError.missingParamList
        }
        self.paramListIndex = paramListIndex
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .methodDef, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
