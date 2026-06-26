enum Implementation {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.file, .exportedType, .assemblyRef]

        case file, assemblyRef, exportedType
    }
}
