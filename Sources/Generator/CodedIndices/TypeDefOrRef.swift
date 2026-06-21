enum TypeDefOrRef {
    case typeDef(TypeDef)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableKind] = [.typeDef, .typeRef, .typeSpec]

        case typeDef, typeRef, typeSpec
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            let typeDef = try TypeDef(metadata: metadata, rowIndex: index.index)
            self = .typeDef(typeDef)
            
        default:
            fatalError("Not implemented yet")
        }
    }
}
