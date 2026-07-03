enum HasConstant {
    case field(Field)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.param, .field, .property]

        case field = 0
        // case param = 1
        // case property = 2
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .field:
            let field = try Field(metadata: metadata, rowIndex: index.index)
            self = .field(field)
        }
    }
}
