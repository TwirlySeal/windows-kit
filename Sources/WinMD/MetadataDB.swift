enum MetadataError: Error {
    case notFound(namespace: String, name: String)
    case ambiguous(namespace: String, name: String)
}

enum Item {
    case type(TypeDef)
    case function(MethodDef)
    case const(Field)
}

public struct MetadataDB {
    let files: [MetadataFile]
    
    // namespace -> name -> [TypeDef]
    private let types: [String: [Substring: [TypeDef]]]
    
    // namespace -> item name -> [Item]
    private let items: [String: [String: [Item]]]
    
    // parent -> children
    private let nested: [TypeDef: [TypeDef]]
    
    /// All namespaces containing at least one item
    var namespaces: some Collection<String> {
        items.keys
    }
    
    var allItems: [Item] {
        items.values.flatMap { dict in
            dict.values.flatMap { $0 }
        }
    }
    
    /// Returns all items within a specific namespace.
    func items(inNamespace namespace: String) -> [String: [Item]] {
        items[namespace] ?? [:]
    }
    
    /// Returns the items matching a namespace and name.
    func getItems(namespace: String, name: String) -> [Item] {
        items[namespace]?[name] ?? []
    }
    
    /// Returns the single `Item` matching the namespace and name.
    /// Throws an error if zero or multiple items are found.
    func expectItem(namespace: String, name: String) throws -> Item {
        let results = getItems(namespace: namespace, name: name)
        
        if results.isEmpty {
            throw MetadataError.notFound(namespace: namespace, name: name)
        } else if results.count > 1 {
            throw MetadataError.ambiguous(namespace: namespace, name: name)
        }
        
        return results[0]
    }
    
    /// Returns the single `TypeDef` matching the namespace and name.
    func expectType(namespace: String, name: Substring) throws -> TypeDef {
        let results = types[namespace]?[name] ?? []
        
        if results.isEmpty {
            throw MetadataError.notFound(
                namespace: namespace,
                name: String(name)
            )
        } else if results.count > 1 {
            throw MetadataError.ambiguous(
                namespace: namespace,
                name: String(name)
            )
        }
        
        return results[0]
    }
    
    /// Returns the types directly nested inside `typeDef`.
    func nestedTypes(for typeDef: TypeDef) -> [TypeDef] {
        nested[typeDef] ?? []
    }

    /// Performs a depth-first walk of every type nested directly or transitively inside `typeDef`.
    func nestedTypesRecursive(for typeDef: TypeDef) -> [TypeDef] {
        var result: [TypeDef] = []
        collectNested(for: typeDef, into: &result)
        return result
    }
    
    private func collectNested(for typeDef: TypeDef, into array: inout [TypeDef]) {
        for inner in nestedTypes(for: typeDef) {
            array.append(inner)
            collectNested(for: inner, into: &array)
        }
    }
    
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
    
    public init(files: [MetadataFile]) throws {
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
