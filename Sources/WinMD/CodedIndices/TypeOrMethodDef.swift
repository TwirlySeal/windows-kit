enum TypeOrMethodDef {
    case typeDef(TypeDef)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.typeDef, .methodDef]
        
        case typeDef = 0
//        case methodDef = 1
    }
    
    init(in file: MetadataFile, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeDef:
            self = .typeDef(
                try TypeDef(in: file, at: index.index)
            )
        }
    }
}
