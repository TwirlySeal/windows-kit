enum TypeOrMethodDef {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableKind] = [.typeDef, .methodDef]
        
        case typeDef, methodDef
    }
}
