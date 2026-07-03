enum Implementation {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.file, .exportedType, .assemblyRef]

        case file = 0
        case assemblyRef = 1
        case exportedType = 2
    }
}
