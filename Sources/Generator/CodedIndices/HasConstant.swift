enum HasConstantError: Error {
    case invalidTable
}

enum HasConstant {
    case field(Field)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.param, .field, .property]

        case field, param, property
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .field:
            let field = try Field(metadata: metadata, rowIndex: index.index)
            self = .field(field)
            
        default:
            throw HasConstantError.invalidTable
        }
    }
}
