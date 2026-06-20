import BinaryParsing

struct TypeDef {
    private let metadata: MetadataDB
    let flags: TypeAttributes
    private let typeNameIndex: UInt32
    private let typeNamespaceIndex: UInt32
    private let extendsIndex: CodedIndex<TypeDefOrRefTag>?
    private let fieldListIndex: UInt32
    private let methodListIndex: UInt32
    
    enum TypeDefError: Error {
        case invalidTypeAttributes
    }
    
    var typeName: String {
        get throws { try metadata.string(at: Int(typeNameIndex)) }
    }
    
    var typeNamespace: String {
        get throws { try metadata.string(at: Int(typeNamespaceIndex)) }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span)) else {
            throw TypeDefError.invalidTypeAttributes
        }
        self.flags = flags
        
        self.typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        
        let extendsValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.typeDefOrRef))
        self.extendsIndex = try CodedIndex<TypeDefOrRefTag>(rawValue: Int(extendsValue))
        
        self.fieldListIndex = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.field))
        self.methodListIndex = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.methodDef))
    }
    
    init(metadata: MetadataDB, rowIndex: Int) throws {
        self = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
