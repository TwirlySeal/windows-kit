enum HasCustomAttribute {
    case methodDef(MethodDef)
    case field(Field)
    case typeRef(TypeRef)
    case typeDef(TypeDef)
    case param(Param)
    case interfaceImpl(InterfaceImpl)
    case memberRef(MemberRef)
    case typeSpec(TypeSpec)
    case genericParam(GenericParam)
    
    init(in metadata: MetadataDB, at index: CodedIndex<Tag>) throws {
        switch index.tag {
        case .methodDef:
            self = .methodDef(
                try MethodDef(in: metadata, at: index.index)
            )
            
        case .field:
            self = .field(
                try Field(in: metadata, at: index.index)
            )
        
        case .typeRef:
            self = .typeRef(
                try TypeRef(in: metadata, at: index.index)
            )
            
        case .typeDef:
            self = .typeDef(
                try TypeDef(in: metadata, at: index.index)
            )
            
        case .param:
            self = .param(
                try Param(in: metadata, at: index.index)
            )
            
        case .interfaceImpl:
            self = .interfaceImpl(
                try InterfaceImpl(in: metadata, at: index.index)
            )
            
        case .memberRef:
            self = .memberRef(
                try MemberRef(in: metadata, at: index.index)
            )
        
        case .typeSpec:
            self = .typeSpec(
                try TypeSpec(in: metadata, at: index.index)
            )
            
        case .genericParam:
            self = .genericParam(
                try GenericParam(in: metadata, at: index.index)
            )
        }
    }
    
    enum Tag: Index.RawValue, CodedIndexTag {
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
//        case module = 7
//        case permission = 8 // this does not correspond to a table
//        case property = 9
//        case event = 10
//        case standAloneSig = 11
//        case moduleRef = 12
        case typeSpec = 13
//        case assembly = 14
//        case assemblyRef = 15
//        case file = 16
//        case exportedType = 17
//        case manifestResource = 18
        case genericParam = 19
//        case genericParamConstraint = 20
//        case methodSpec = 21
    }
}
