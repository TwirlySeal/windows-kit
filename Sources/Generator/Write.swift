import WinMD

func hasAttribute(
    _ attributes: [CustomAttribute],
    namespace: String,
    name: String
) throws -> Bool {
    try attributes.contains { attribute in
        let parent = try attribute.type.parent
        return try parent.name == name && parent.namespace == namespace
    }
}

func hasModifier(
    _ modifiers: [CustomMod],
    namespace: String,
    name: String
) throws -> Bool {
    try modifiers.contains { modifier in
        let type = try modifier.type
        return try type.name == name && type.namespace == namespace
    }
}

func write(type: TypeDef) throws {
    let category = try type.category
    
    if type.flags.implementation.contains(.windowsRuntime) {
        // WinRT
        switch category {
        case .enum:
            try write(enum: type)
        case .delegate:
            print("WinRT delegate")
        case .struct:
            try write(struct: type)
        case .attribute:
            // Attributes are looked up on other items
            print("WinRT attribute (ignored)")
            return
        case .class:
            try write(class: type)
        case .interface:
            print("WinRT interface")
        }
    } else {
        // Win32
        switch category {
        case .enum:
            print("Win32 enum")
        case .delegate:
            print("Win32 delegate")
        case .struct:
            print("Win32 struct")
        case .attribute:
            // Attributes are looked up on other items
            print("Win32 attribute (ignored)")
            return
        case .class:
            let name = try type.name
            
            // The "Apis" class is used for Win32 functions and constants
            if name == "Apis" {
                for method in try type.methods {
                    print("Win32 method: \(try method.name)")
                }
                
                for field in try type.fields {
                    print("Win32 field: \(try field.name)")
                }
            } else {
                // Other non-WinRT classes do not contribute types
                return
            }
        case .interface:
            print("Win32 interface")
        }
    }
}
