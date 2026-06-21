enum HasSemantics {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableKind] = [.event, .property]

        case event, property
    }
}
