enum HasFieldMarshal {
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableKind] = [.field, .param]

        case field, param
    }
}
