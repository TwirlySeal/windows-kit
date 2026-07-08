enum TypeDefOrRefError: Error {
    case disallowedTypeSpec
}

enum TypeDefOrRef {
    case typeDef(TypeDef)
    case typeRef(TypeRef)
    case typeSpec(TypeSpec)
    
    var name: String {
        get throws {
            switch self {
            case .typeDef(let typeDef):
                try typeDef.name
            case .typeRef(let typeRef):
                try typeRef.name
            case .typeSpec(let typeSpec):
                throw TypeDefOrRefError.disallowedTypeSpec
            }
        }
    }
    
    var namespace: String {
        get throws {
            switch self {
            case .typeDef(let typeDef):
                try typeDef.namespace
            case .typeRef(let typeRef):
                try typeRef.namespace
            case .typeSpec(let typeSpec):
                throw TypeDefOrRefError.disallowedTypeSpec
            }
        }
    }
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.typeDef, .typeRef, .typeSpec]

        case typeDef = 0
        case typeRef = 1
        case typeSpec = 2
    }
    
    init(in file: MetadataFile, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            self = .typeDef(
                try TypeDef(in: file, at: index.index)
            )
            
        case .typeRef:
            self = .typeRef(
                try TypeRef(in: file, at: index.index)
            )
            
        case .typeSpec:
            self = .typeSpec(
                try TypeSpec(in: file, at: index.index)
            )
        }
    }
}
