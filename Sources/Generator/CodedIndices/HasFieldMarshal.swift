enum HasFieldMarshal {
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .param]

        case field = 0
        case param = 1
    }
}
