enum CustomAttributeType {
    case methodDef(MethodDef)
    case memberRef(MemberRef)
    
    init(in file: MetadataFile, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .methodDef:
            self = .methodDef(
                try MethodDef(in: file, at: index.index)
            )
            
        case .memberRef:
            self = .memberRef(
                try MemberRef(in: file, at: index.index)
            )
        }
    }
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 3
        static let tables: [TableID] = [.methodDef, .memberRef]

        // Not used - 0
        // Not used - 1
        case methodDef = 2
        case memberRef = 3
        // Not used - 4
    }
}
