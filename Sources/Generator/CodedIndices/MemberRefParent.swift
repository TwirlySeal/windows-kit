enum MemberRefParent {
    enum Tag: Int, CodedIndexTag {
        static let bits = 3
        static let tables: [TableKind] = [.methodDef, .moduleRef, .typeDef, .typeRef, .typeSpec]

        case typeDef, typeRef, moduleRef, methodDef, typeSpec
    }
}
