enum HasDeclSecurity {
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.typeDef, .methodDef, .assembly]

        case typeDef = 0
        case methodDef = 1
        case assembly = 2
    }
}
