enum MemberForwardedError: Error {
    case invalidTable
}

enum MemberForwarded {
    case methodDef(MethodDef)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 1
        static let tables: [TableID] = [.field, .methodDef]

        case field, methodDef
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .methodDef:
            let methodDef = try MethodDef(metadata: metadata, rowIndex: index.index)
            self = .methodDef(methodDef)
        default:
            throw MemberForwardedError.invalidTable
        }
    }
}
