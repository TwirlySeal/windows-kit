enum HasDeclSecurity {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableKind] = [.typeDef, .methodDef, .assembly]

        case typeDef, methodDef, assembly
    }
}
