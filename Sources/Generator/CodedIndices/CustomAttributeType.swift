enum CustomAttributeType {
    enum Tag: Int, CodedIndexTag {
        static let bits = 3
        static let tables: [TableID] = [.methodDef, .memberRef]

        // Not used - 0
        // Not used - 1
        case methodDef = 2
        case memberRef = 3
        // Not used - 4
    }
}
