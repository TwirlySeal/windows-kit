enum HasCustomAttribute {
    enum Tag: Int, CodedIndexTag {
        static let bits = 5
        static let tables: [TableID] = [
            .methodDef,
            .field,
            .typeRef,
            .typeDef,
            .param,
            .interfaceImpl,
            .memberRef,
            .module,
            .property,
            .event,
            .standAloneSig,
            .moduleRef,
            .typeSpec,
            .assembly,
            .assemblyRef,
            .file,
            .exportedType,
            .manifestResource,
            .genericParam,
            .genericParamConstraint,
            .methodSpec
        ]

        case methodDef = 0
        case field = 1
        case typeRef = 2
        case typeDef = 3
        case param = 4
        case interfaceImpl = 5
        case memberRef = 6
        case module = 7
        case permission = 8 // this does not correspond to a table
        case property = 9
        case event = 10
        case standAloneSig = 11
        case moduleRef = 12
        case typeSpec = 13
        case assembly = 14
        case assemblyRef = 15
        case file = 16
        case exportedType = 17
        case manifestResource = 18
        case genericParam = 19
        case genericParamConstraint = 20
        case methodSpec = 21
    }
}
