enum HasFieldMarshal {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .param]

        case field, param
    }
}
