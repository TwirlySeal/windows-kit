enum MemberRefParent {
    enum Tag: Int, CodedIndexTag {
        static let bits = 3
        static let tables: [TableID] = [.methodDef, .moduleRef, .typeDef, .typeRef, .typeSpec]

        case typeDef = 0
        case typeRef = 1
        case moduleRef = 2
        case methodDef = 3
        case typeSpec = 4
    }
}
