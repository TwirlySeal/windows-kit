enum MemberForwarded {
    case methodDef(MethodDef)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .methodDef]

        // case field = 0
        case methodDef = 1
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .methodDef:
            let methodDef = try MethodDef(metadata: metadata, rowIndex: index.index)
            self = .methodDef(methodDef)
        }
    }
}
