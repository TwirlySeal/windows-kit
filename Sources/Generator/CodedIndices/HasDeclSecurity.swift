enum HasDeclSecurity {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.typeDef, .methodDef, .assembly]

        case typeDef, methodDef, assembly
    }
}
