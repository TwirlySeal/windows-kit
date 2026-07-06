enum ResolutionScope {
    case typeRef(TypeRef)
    case moduleRef(ModuleRef)
    
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.module, .moduleRef, .assemblyRef, .typeRef]

//        case module = 0
        case moduleRef = 1
//        case assemblyRef = 2
        case typeRef = 3
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeRef:
            self = .typeRef(
                try TypeRef(metadata: metadata, rowIndex: index.index)
            )
        case .moduleRef:
            self = .moduleRef(
                try ModuleRef(metadata: metadata, rowIndex: index.index)
            )
        }
    }
}
