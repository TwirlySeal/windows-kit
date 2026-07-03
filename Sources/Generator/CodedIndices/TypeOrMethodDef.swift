enum TypeOrMethodDef {
    case typeDef(TypeDef)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.typeDef, .methodDef]
        
        case typeDef = 0
//        case methodDef = 1
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            let typeDef = try TypeDef(metadata: metadata, rowIndex: index.index)
            self = .typeDef(typeDef)
        }
    }
}
