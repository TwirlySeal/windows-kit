enum MethodDefOrRef {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableKind] = [.methodDef, .memberRef]

        case methodDef, memberRef
    }
}
