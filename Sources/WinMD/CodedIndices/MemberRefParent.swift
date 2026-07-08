enum MemberRefParent {
    case typeDef(TypeDef)
    case typeRef(TypeRef)
    
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
        }
    }
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 3
        static let tables: [TableID] = [.methodDef, .moduleRef, .typeDef, .typeRef, .typeSpec]

        case typeDef = 0
        case typeRef = 1
//        case moduleRef = 2
//        case methodDef = 3
//        case typeSpec = 4
    }
}
