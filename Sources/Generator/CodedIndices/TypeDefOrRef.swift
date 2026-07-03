enum TypeDefOrRef {
    case typeDef(TypeDef)
    case typeRef(TypeRef)
    case typeSpec(TypeSpec)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.typeDef, .typeRef, .typeSpec]

        case typeDef = 0
        case typeRef = 1
        case typeSpec = 2
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            let typeDef = try TypeDef(metadata: metadata, rowIndex: index.index)
            self = .typeDef(typeDef)
            
        case .typeRef:
            let typeRef = try TypeRef(metadata: metadata, rowIndex: index.index)
            self = .typeRef(typeRef)
            
        case .typeSpec:
            let typeSpec = try TypeSpec(metadata: metadata, rowIndex: index.index)
            self = .typeSpec(typeSpec)
        }
    }
}
