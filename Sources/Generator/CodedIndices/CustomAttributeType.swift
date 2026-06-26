enum CustomAttributeType {
    enum Tag: Int, CodedIndexTag {
        static let bits = 3
        static let tables: [TableID] = [.methodDef, .memberRef]

        // Not used
        // Not used
        case methodDef = 2, memberRef
        // Not used
    }
}
