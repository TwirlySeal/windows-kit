enum MethodDefOrRef {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.methodDef, .memberRef]

        case methodDef, memberRef
    }
}
