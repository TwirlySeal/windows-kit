enum TypeOrMethodDefError: Error {
    case invalidTable
}

enum TypeOrMethodDef {
    case typeDef(TypeDef)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.typeDef, .methodDef]
        
        case typeDef, methodDef
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            let typeDef = try TypeDef(metadata: metadata, rowIndex: index.index)
            self = .typeDef(typeDef)
            
        default:
            throw TypeOrMethodDefError.invalidTable
        }
    }
}
