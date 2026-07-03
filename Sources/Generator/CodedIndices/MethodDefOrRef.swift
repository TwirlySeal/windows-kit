enum MethodDefOrRef {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.methodDef, .memberRef]

        case methodDef = 0
        case memberRef = 1
    }
}
