enum ResolutionScope {
    enum Tag: Index.RawValue, CodedIndexTag {
        static let bits = 2
        static let tables: [TableID] = [.module, .moduleRef, .assemblyRef, .typeRef]

        case module = 0
        case moduleRef = 1
        case assemblyRef = 2
        case typeRef = 3
    }
}
