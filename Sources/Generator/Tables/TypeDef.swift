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
        
        self.typeNameIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: metadata.heapSizes.stringSize)
        
        self.extendsIndex = try CodedIndex<TypeDefOrRef.Tag>(parsing: &span, size: metadata.codedIndexSizes.typeDefOrRef)
        
        self.fieldListIndex = try Index(parsing: &span, size: metadata.indexSizes.field)
        
        self.methodListIndex = try Index(parsing: &span, size: metadata.indexSizes.methodDef)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span, rowIndex: rowIndex)
        }
    }
}
