enum ResolutionScope {
    case typeRef(TypeRef)
    case moduleRef(ModuleRef)
    
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.module, .moduleRef, .assemblyRef, .typeRef]

        case module, moduleRef, assemblyRef, typeRef
    }
    
    enum ResolutionScopeError: Error {
        case invalidTable
    }
    
    init(metadata: MetadataDB, index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .typeRef:
            let typeRef = try TypeRef(metadata: metadata, rowIndex: index.index)
            self = .typeRef(typeRef)
        case .moduleRef:
            let moduleRef = try ModuleRef(metadata: metadata, rowIndex: index.index)
            self = .moduleRef(moduleRef)
        default:
            throw ResolutionScopeError.invalidTable
        }
    }
}
