enum MemberForwarded {
    case methodDef(MethodDef)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .methodDef]

//        case field = 0
        case methodDef = 1
    }
    
    init(in metadata: MetadataDB, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .methodDef:
            self = .methodDef(
                try MethodDef(in: metadata, at: index.index)
            )
        }
    }
}
