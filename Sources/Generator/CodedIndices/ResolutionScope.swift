enum ResolutionScope {
    enum Tag: Int, CodedIndexTag {
        static let bits = 2
        static let tables: [TableKind] = [.module, .moduleRef, .assemblyRef, .typeRef]

        case module, moduleRef, assemblyRef, typeRef
    }
}
