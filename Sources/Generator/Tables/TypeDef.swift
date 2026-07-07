import BinaryParsing

enum TypeDefError: Error {
    case invalidTypeAttributes
}

struct TypeDef {
    private let metadata: MetadataDB
    private let rowIndex: Index
    
    let flags: TypeAttributes
    private let typeNameIndex: HeapIndex
    private let typeNamespaceIndex: HeapIndex
    private let extendsIndex: CodedIndex<TypeDefOrRef.Tag>?
    private let fieldListIndex: Index?
    private let methodListIndex: Index?
    
    var name: String {
        get throws { try metadata.string(at: typeNameIndex) }
    }
    
    var namespace: String {
        get throws { try metadata.string(at: typeNamespaceIndex) }
    }
    
    var extends: TypeDefOrRef? {
        get throws {
            try extendsIndex.map { index in
                try .init(in: metadata, at: index)
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
                try Self(in: metadata, at: rowIndex).fieldListIndex
            }
            
            return try range.map { index in
                try Field(in: metadata, at: index)
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
                try Self(in: metadata, at: rowIndex).methodListIndex
            }
            
            return try range.map { index in
                try MethodDef(in: metadata, at: index)
            }
        }
    }
    
    var genericParams: [GenericParam] {
        get throws {
            try GenericParam.equalRange(in: metadata, tag: .typeDef, index: self.rowIndex)
                .map { index in
                    try GenericParam(in: metadata, at: index)
                }
        }
    }
    
    var interfaceImpls: [InterfaceImpl] {
        get throws {
            try InterfaceImpl.equalRange(in: metadata, index: self.rowIndex)
                .map { index in
                    try InterfaceImpl(in: metadata, at: index)
                }
        }
    }
    
    var classLayout: ClassLayout? {
        get throws {
            try ClassLayout.equalRange(in: metadata, index: self.rowIndex)
                .first
                .map { index in
                    try ClassLayout(in: metadata, at: index)
                }
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: metadata,
                tag: .typeDef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: metadata, at: index)
            }
        }
    }
    
    private init(in metadata: MetadataDB, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.metadata = metadata
        self.rowIndex = rowIndex
        
        guard let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span)) else {
            throw TypeDefError.invalidTypeAttributes
        }
        self.flags = flags
        
        self.typeNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        
        self.extendsIndex = try CodedIndex<TypeDefOrRef.Tag>(parsing: &span, size: metadata.codedIndexSizes.typeDefOrRef)
        
        self.fieldListIndex = try Index(parsing: &span, size: metadata.indexSizes.field)
        
        self.methodListIndex = try Index(parsing: &span, size: metadata.indexSizes.methodDef)
    }
    
    init(in metadata: MetadataDB, at rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeDef, at: rowIndex) { span in
            try Self(in: metadata, parsing: &span, rowIndex)
        }
    }
}
