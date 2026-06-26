enum TypeOrMethodDef {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.typeDef, .methodDef]
        
        case typeDef, methodDef
    }
}
