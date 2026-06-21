import BinaryParsing

struct TypeDef {
    private let metadata: MetadataDB
    private let rowIndex: Int
    
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
    
    var fields: some Sequence<Field> {
        get throws {
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: Int(fieldListIndex),
                currentTable: .typeDef,
                linkedTable: .field
            ) { nextRowIndex in
                Int(try Self(metadata: metadata, rowIndex: nextRowIndex).fieldListIndex)
            }
            
            return try range.lazy.map { index in
                try Field(metadata: self.metadata, rowIndex: index)
            }
        }
    }
    
    var methods: some Sequence<MethodDef> {
        get throws {
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: Int(methodListIndex),
                currentTable: .typeDef,
                linkedTable: .methodDef
            ) { nextRowIndex in
                Int(try Self(metadata: metadata, rowIndex: nextRowIndex).methodListIndex)
            }
            
            return try range.lazy.map { index in
                try MethodDef(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan, rowIndex: Int) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
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
            try Self(metadata: metadata, span: &span, rowIndex: rowIndex)
        }
    }
}
