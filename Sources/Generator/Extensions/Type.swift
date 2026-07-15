import WinMD

extension Type {
    func swiftTypeName(precedingModifiers: [CustomMod]) throws -> String {
        // Inner modifiers apply to the element type
        
        switch self {
        case .boolean: return "Bool"
        case .char:
            // .NET `char` is a 16-bit UTF-16 code unit. Swift's `Character`
            // is a grapheme cluster, and `CChar` is 8-bit. This type is a
            // typealias for `UInt16`.
            return "Unicode.UTF16.CodeUnit"
        case .int8: return "Int8"
        case .uint8: return "UInt8"
        case .int16: return "Int16"
        case .uint16: return "UInt16"
        case .int32: return "Int32"
        case .uint32: return "UInt32"
        case .int64: return "Int64"
        case .uint64: return "UInt64"
        case .float32: return "Float"
        case .float64: return "Double"
        case .int: return "Int"
        case .uint: return "UInt"
        case .string: return "String"
        case .object:
            // IInspectable for WinRT, IUnknown for Win32?
            fatalError("Unhandled type: Object")
            
        case .array(element: _, shape: _):
            fatalError("Unhandled type: array (multi-dimensional)")
            
        case .class(let type), .valueType(let type):
            return try type.value.name
            
        case .enum(let name): return name
            
        case .genericInstance(genericInstance: _):
            fatalError("Unhandled type: generic instance")
            
        case .genericTypeParameter(index: _):
            // "T\(index)"?
            // `T0`, `T1`, etc.
            fatalError("Unhandled type: generic type parameter")
            
        case .pointer(let pointer):
            let isConst = try hasModifier(
                precedingModifiers,
                namespace: "System.Runtime.CompilerServices",
                name: "IsConst"
            )
            
            switch pointer.pointee {
            case .void:
                return if isConst {
                    "UnsafeRawPointer"
                } else {
                    "UnsafeMutableRawPointer"
                }
            case .type(let type):
                let elementTypeName = try type.swiftTypeName(precedingModifiers: pointer.customModifiers)
                return if isConst {
                    "UnsafePointer<\(elementTypeName)>"
                } else {
                    "UnsafeMutablePointer<\(elementTypeName)>"
                }
            }
            
        case .vector(let innerModifiers, let element):
            let elementTypeName = try element.swiftTypeName(precedingModifiers: innerModifiers)
            return "[\(elementTypeName)]"
        }
    }
}
