public struct MetadataDB {
    /// namespace -> name -> [TypeDef]
    public let types: [String: [String: [TypeDef]]]
    
    /// parent -> children
    public let nested: [TypeDef: [TypeDef]]
    
    // Removes the generic arity suffix (e.g. `1, `2) from type names, which
    // indicates the number of generic parameters
    public static func trimGenericArity(_ name: Substring) -> Substring {
        if let index = name.firstIndex(of: "`") {
            return name[..<index]
        }
        return name
    }
    
    public init(files: [MetadataFile]) throws {
        var types: [String: [String: [TypeDef]]] = [:]
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
                
                types[namespace, default: [:]][String(cleanName), default: []]
                    .append(typeDef)
            }
            
            for index in try file.tableRange(in: .nestedClass) {
                let nestedClass = try NestedClass(in: file, at: index)
                
                let inner = try nestedClass.nestedClass
                let outer = try nestedClass.enclosingClass
                
                nested[outer, default: []].append(inner)
            }
        }
        self.nested = nested
        self.types = types
    }
}
