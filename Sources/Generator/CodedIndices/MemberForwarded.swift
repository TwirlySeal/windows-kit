enum MemberForwarded {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .methodDef]

        case field, methodDef
    }
}
