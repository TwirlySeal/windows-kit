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

        case methodDef
        case field
        case typeRef
        case typeDef
        case param
        case interfaceImpl
        case memberRef
        case module
        case permission // this does not correspond to a table
        case property
        case event
        case standAloneSig
        case moduleRef
        case typeSpec
        case assembly
        case assemblyRef
        case file
        case exportedType
        case manifestResource
        case genericParam
        case genericParamConstraint
        case methodSpec
    }
}
