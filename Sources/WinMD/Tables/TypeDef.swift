import BinaryParsing

enum TypeDefError: Error {
    case invalidTypeAttributes
    case invalidExtends
}

public struct TypeDef {
    private let file: MetadataFile
    private let rowIndex: Index
    
    public let flags: TypeAttributes
    private let typeNameIndex: HeapIndex
    private let typeNamespaceIndex: HeapIndex
    private let extendsIndex: CodedIndex<TypeDefOrRef.Tag>?
    private let fieldListIndex: Index?
    private let methodListIndex: Index?
    
    public var name: String {
        get throws { try file.string(at: typeNameIndex) }
    }
    
    var namespace: String {
        get throws { try file.string(at: typeNamespaceIndex) }
    }
    
    public var extends: TypeDefOrRef? {
        get throws {
            try extendsIndex.map { index in
                try .init(in: file, at: index)
            }
        }
    }
    
    public var fields: [Field] {
        get throws {
            guard let fieldListIndex else {
                return []
            }
            
            let range = try file.listRowRange(
                forParentRow: self.rowIndex,
                startingChildIndex: fieldListIndex,
                parentTableID: .typeDef,
                childTableID: .field
            ) { rowIndex in
                try Self(in: file, at: rowIndex).fieldListIndex
            }
            
            return try range.map { index in
                try Field(in: file, at: index)
            }
        }
    }
    
    public var methods: [MethodDef] {
        get throws {
            guard let methodListIndex else {
                return []
            }
            
            let range = try file.listRowRange(
                forParentRow: self.rowIndex,
                startingChildIndex: methodListIndex,
                parentTableID: .typeDef,
                childTableID: .methodDef
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
            try GenericParam.rowRange(tag: .typeDef, forOwner: self.rowIndex, in: file)
                .map { index in
                    try GenericParam(in: file, at: index)
                }
        }
    }
    
    public var interfaceImpls: [InterfaceImpl] {
        get throws {
            try InterfaceImpl.rowRange(forOwner: self.rowIndex, in: file)
                .map { index in
                    try InterfaceImpl(in: file, at: index)
                }
        }
    }
    
    var classLayout: ClassLayout? {
        get throws {
            try ClassLayout.rowRange(forParent: self.rowIndex, in: file)
                .first
                .map { index in
                    try ClassLayout(in: file, at: index)
                }
        }
    }
    
    public var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.rowRange(
                tag: .typeDef,
                forParent: self.rowIndex,
                in: file
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    /// Get the index of the `TypeDef` that is the parent of a `MethodDef` at `index`
    static func parentOfMethod(at index: Index, in file: MetadataFile) throws -> Index {
        try file.parentRow(searchingParentTable: .typeDef) { rowIndex in
            try TypeDef(in: file, at: rowIndex)
                .methodListIndex!.compare(to: index)
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
    public static func == (lhs: TypeDef, rhs: TypeDef) -> Bool {
        // Both must reside in the same file instance and point to the same row
        // index
        lhs.file === rhs.file && lhs.rowIndex == rhs.rowIndex
    }
}

extension TypeDef: Hashable {
    public func hash(into hasher: inout Hasher) {
        // Combine the memory address of the file class instance
        hasher.combine(ObjectIdentifier(file))
        // Combine the unique row index value
        hasher.combine(rowIndex)
    }
}
