import BinaryParsing

enum TypeDefError: Error {
    case invalidTypeAttributes
    case invalidExtends
}

struct TypeDef {
    private let file: MetadataFile
    private let rowIndex: Index
    
    let flags: TypeAttributes
    private let typeNameIndex: HeapIndex
    private let typeNamespaceIndex: HeapIndex
    private let extendsIndex: CodedIndex<TypeDefOrRef.Tag>?
    private let fieldListIndex: Index?
    private let methodListIndex: Index?
    
    var name: String {
        get throws { try file.string(at: typeNameIndex) }
    }
    
    var namespace: String {
        get throws { try file.string(at: typeNamespaceIndex) }
    }
    
    var extends: TypeDefOrRef? {
        get throws {
            try extendsIndex.map { index in
                try .init(in: file, at: index)
            }
        }
    }
    
    var fields: [Field] {
        get throws {
            guard let fieldListIndex else {
                return []
            }
            
            let range = try file.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: fieldListIndex,
                currentTable: .typeDef,
                linkedTable: .field
            ) { rowIndex in
                try Self(in: file, at: rowIndex).fieldListIndex
            }
            
            return try range.map { index in
                try Field(in: file, at: index)
            }
        }
    }
    
    var methods: [MethodDef] {
        get throws {
            guard let methodListIndex else {
                return []
            }
            
            let range = try file.listRowRange(
                rowIndex: self.rowIndex,
                startListIndex: methodListIndex,
                currentTable: .typeDef,
                linkedTable: .methodDef
            ) { rowIndex in
                try Self(in: file, at: rowIndex).methodListIndex
            }
            
            return try range.map { index in
                try MethodDef(in: file, at: index)
            }
        }
    }
    
    var genericParams: [GenericParam] {
        get throws {
            try GenericParam.equalRange(in: file, tag: .typeDef, index: self.rowIndex)
                .map { index in
                    try GenericParam(in: file, at: index)
                }
        }
    }
    
    var interfaceImpls: [InterfaceImpl] {
        get throws {
            try InterfaceImpl.equalRange(in: file, index: self.rowIndex)
                .map { index in
                    try InterfaceImpl(in: file, at: index)
                }
        }
    }
    
    var classLayout: ClassLayout? {
        get throws {
            try ClassLayout.equalRange(in: file, index: self.rowIndex)
                .first
                .map { index in
                    try ClassLayout(in: file, at: index)
                }
        }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .typeDef,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    enum Category {
        case `enum`
        case delegate
        case `struct`
        case attribute
        case `class`
        case interface
    }
    
    var category: Category {
        get throws {
            guard let extends = try extends else {
                return .interface
            }
            
            guard try extends.namespace == "System" else {
                return .class
            }
            
            return switch try extends.name {
            case "Enum":
                .enum
                
            case "MulticastDelegate":
                .delegate
                
            case "ValueType":
                .struct
                
            case "Attribute":
                .attribute
                
            default:
                .class
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        guard let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span)) else {
            throw TypeDefError.invalidTypeAttributes
        }
        self.flags = flags
        
        self.typeNameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        
        self.extendsIndex = try CodedIndex<TypeDefOrRef.Tag>(parsing: &span, size: file.codedIndexSizes.typeDefOrRef)
        
        self.fieldListIndex = try Index(parsing: &span, size: file.indexSizes.field)
        
        self.methodListIndex = try Index(parsing: &span, size: file.indexSizes.methodDef)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .typeDef, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}

extension TypeDef: Equatable {
    static func == (lhs: TypeDef, rhs: TypeDef) -> Bool {
        // Both must reside in the same file instance and point to the same row
        // index
        lhs.file === rhs.file && lhs.rowIndex == rhs.rowIndex
    }
}

extension TypeDef: Hashable {
    func hash(into hasher: inout Hasher) {
        // Combine the memory address of the file class instance
        hasher.combine(ObjectIdentifier(file))
        // Combine the unique row index value
        hasher.combine(rowIndex)
    }
}
