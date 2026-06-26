enum HasConstant {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.param, .field, .property]

        case field, param, property
    }
}
