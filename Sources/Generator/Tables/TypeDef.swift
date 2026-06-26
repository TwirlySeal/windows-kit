import BinaryParsing

struct TypeDef {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    let flags: TypeAttributes
    private let typeNameIndex: UInt32
    private let typeNamespaceIndex: UInt32
    private let extendsIndex: CodedIndex<TypeDefOrRef.Tag>?
    private let fieldListIndex: Index?
    private let methodListIndex: Index?
    
    enum TypeDefError: Error {
        case invalidTypeAttributes
    }
    
    var name: String {
        get throws { try metadata.string(at: Int(typeNameIndex)) }
    }
    
    var namespace: String {
        get throws { try metadata.string(at: Int(typeNamespaceIndex)) }
    }
    
    var extends: TypeDefOrRef? {
        get throws {
            try extendsIndex.map { index in
                try .init(metadata: metadata, index: index)
            }
        }
    }
    
    var fields: [Field] {
        get throws {
            guard let fieldListIndex else {
                return []
            }
            
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: fieldListIndex,
                currentTable: .typeDef,
                linkedTable: .field
            ) { rowIndex in
                try Self(metadata: metadata, rowIndex: rowIndex).fieldListIndex
            }
            
            return try range.map { index in
                try Field(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    var methods: [MethodDef] {
        get throws {
            guard let methodListIndex else {
                return []
            }
            
            let range = try metadata.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: methodListIndex,
                currentTable: .typeDef,
                linkedTable: .methodDef
            ) { rowIndex in
                try Self(metadata: metadata, rowIndex: rowIndex).methodListIndex
            }
            
            return try range.map { index in
                try MethodDef(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    var genericParams: [GenericParam] {
        get throws {
            let range = try metadata.equalRange(in: .genericParam) { rowIndex in
                try GenericParam(metadata: metadata, rowIndex: rowIndex)
                    .compareOwnerIndex(index: self.rowIndex)
            }
            
            return try range.map { index in
                try GenericParam(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    var interfaceImpls: [InterfaceImpl] {
        get throws {
            let range = try metadata.equalRange(in: .interfaceImpl) { rowIndex in
                try InterfaceImpl(metadata: metadata, rowIndex: rowIndex)
                    .compareClassIndex(index: self.rowIndex)
            }
            
            return try range.map { index in
                try InterfaceImpl(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    var classLayout: ClassLayout? {
        get throws {
            let range = try metadata.equalRange(in: .classLayout) { rowIndex in
                try ClassLayout(metadata: metadata, rowIndex: rowIndex)
                    .compareParentIndex(index: self.rowIndex)
            }
            
            return try range.first.map { index in
                try ClassLayout(metadata: metadata, rowIndex: index)
            }
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan, rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        guard let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span)) else {
            throw TypeDefError.invalidTypeAttributes
        }
        self.flags = flags
        
        self.typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.stringSize)
        
        let extendsValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.typeDefOrRef))
        self.extendsIndex = try CodedIndex<TypeDefOrRef.Tag>(rawValue: Int(extendsValue))
        
        let fieldList = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.field))
        self.fieldListIndex = Index(rawValue: fieldList)
        
        let methodList = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.methodDef))
        self.methodListIndex = Index(rawValue: methodList)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span, rowIndex: rowIndex)
        }
    }
}
