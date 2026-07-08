enum Item {
    case type(TypeDef)
    case function(MethodDef)
    case const(Field)
}

struct MetadataDB {
    let files: [MetadataFile]
    
    // namespace -> name -> [TypeDef]
    private let types: [String: [Substring: [TypeDef]]]
    
    // namespace -> item name -> [Item]
    private let items: [String: [String: [Item]]]
    
    // parent -> children
    private let nested: [TypeDef: [TypeDef]]
    
    static func trimTick(_ name: Substring) -> Substring {
        if let index = name.firstIndex(of: "`") {
            return name[..<index]
        }
        return name
    }
    
    private static func typeSequence(
        _ types: [String: [Substring: [TypeDef]]]
    ) -> some Sequence<(namespace: String, name: Substring, typeDef: TypeDef)> {
        types.lazy.flatMap { namespace, nestedDict in
            nestedDict.lazy.flatMap { name, typeDefs in
                typeDefs.lazy.map { typeDef in
                    (namespace, name, typeDef)
                }
            }
        }
    }
    
    init(files: [MetadataFile]) throws {
        self.files = files
        
        // Build the type map and nested class map
        var types: [String: [Substring: [TypeDef]]] = [:]
        var nested: [TypeDef: [TypeDef]] = [:]
        
        for file in files {
            for index in try file.tableRange(in: .typeDef) {
                let typeDef = try TypeDef(in: file, at: index)
                
                let namespace = try typeDef.namespace
                if namespace.isEmpty {
                    // Skips `<Module>` as well as nested types
                    continue
                }
                
                let name = try typeDef.name
                let cleanName = Self.trimTick(name[...])
                
                types[namespace, default: [:]][cleanName, default: []].append(typeDef)
            }
            
            for index in try file.tableRange(in: .nestedClass) {
                let nestedClass = try NestedClass(in: file, at: index)
                
                let inner = try nestedClass.nestedClass
                let outer = try nestedClass.enclosingClass
                
                nested[outer, default: []].append(inner)
            }
        }
        self.types = types
        self.nested = nested
        
        // Build the item map
        var items: [String: [String: [Item]]] = [:]
        
        for (namespace, name, typeDef) in Self.typeSequence(types) {
            let category = try typeDef.category
            
            let isApisClass = (
                typeDef.flags.implementation.contains(.windowsRuntime)
                && category == .class && name == "Apis"
            )
            if isApisClass {
                for method in try typeDef.methods {
                    items[namespace, default: [:]][try method.name, default: []]
                        .append(.function(method))
                }
                
                for field in try typeDef.fields {
                    items[namespace, default: [:]][try field.name, default: []]
                        .append(.const(field))
                }
            } else {
                items[namespace, default: [:]][String(name), default: []]
                    .append(.type(typeDef))
            }
        }
        self.items = items
    }
}
