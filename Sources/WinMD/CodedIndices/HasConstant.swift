enum HasConstant {
    case field(Field)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.param, .field, .property]

        case field = 0
//        case param = 1
//        case property = 2
    }
    
    init(in file: MetadataFile, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .field:
            self = .field(
                try Field(in: file, at: index.index)
            )
        }
    }
}
