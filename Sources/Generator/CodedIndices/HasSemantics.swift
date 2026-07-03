enum HasSemantics {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.event, .property]

        case event = 0
        case property = 1
    }
}
