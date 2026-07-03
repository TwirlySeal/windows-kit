enum MethodDefOrRef {
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.methodDef, .memberRef]

        case methodDef = 0
        case memberRef = 1
    }
}
