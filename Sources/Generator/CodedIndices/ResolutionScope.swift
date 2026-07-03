enum ResolutionScope {
    case typeRef(TypeRef)
    case moduleRef(ModuleRef)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.module, .moduleRef, .assemblyRef, .typeRef]

        // case module = 0
        case moduleRef = 1
        // case assemblyRef = 2
        case typeRef = 3
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeRef:
            let typeRef = try TypeRef(metadata: metadata, rowIndex: index.index)
            self = .typeRef(typeRef)
        case .moduleRef:
            let moduleRef = try ModuleRef(metadata: metadata, rowIndex: index.index)
            self = .moduleRef(moduleRef)
        }
    }
}
