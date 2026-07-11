enum Item {
    case type(TypeDef)
    case function(MethodDef)
    case const(Field)
}

public struct MetadataDB {
    let files: [MetadataFile]
    
    // namespace -> item name -> [Item]
    private let items: [String: [String: [Item]]]
    
    // parent -> children
    private let nested: [TypeDef: [TypeDef]]
    
    // Removes the generic arity suffix (e.g. `1, `2) from type names, which
    // indicates the number of generic parameters
    static func trimGenericArity(_ name: Substring) -> Substring {
        if let index = name.firstIndex(of: "`") {
            return name[..<index]
        }
        return name
    }
    
    public init(files: [MetadataFile]) throws {
        self.files = files
        
        var items: [String: [String: [Item]]] = [:]
        var nested: [TypeDef: [TypeDef]] = [:]
        
        for file in files {
            for index in try file.tableRange(in: .typeDef) {
                let typeDef = try TypeDef(in: file, at: index)
                
                let namespace = try typeDef.namespace
                if namespace.isEmpty {
                    // Skips `<Module>` type and nested types
                    continue
                }
                
                let name = try typeDef.name
                let cleanName = Self.trimGenericArity(name[...])
                let category = try typeDef.category
                
                // The "Apis" class is used for Win32 metadata
                let isApisClass = (
                    typeDef.flags.implementation.contains(.windowsRuntime)
                    && category == .class && name == "Apis"
                )
                
                if isApisClass {
                    // Extract Win32 APIs
                    for method in try typeDef.methods {
                        items[namespace, default: [:]][try method.name, default: []]
                            .append(.function(method))
                    }
                    
                    for field in try typeDef.fields {
                        items[namespace, default: [:]][try field.name, default: []]
                            .append(.const(field))
                    }
                } else {
                    items[namespace, default: [:]][String(cleanName), default: []]
                        .append(.type(typeDef))
                }
            }
            
            for index in try file.tableRange(in: .nestedClass) {
                let nestedClass = try NestedClass(in: file, at: index)
                
                let inner = try nestedClass.nestedClass
                let outer = try nestedClass.enclosingClass
                
                nested[outer, default: []].append(inner)
            }
        }
        self.nested = nested
        self.items = items
    }
}
