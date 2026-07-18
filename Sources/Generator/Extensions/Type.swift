import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

extension Type {
    /// Generates the equivalent Swift type name for this WinMD type
    ///
    /// ### Custom Modifiers
    /// Custom modifiers apply to the type node immediately following them. For
    /// pointer types, inner modifiers apply to the **pointee** (the data being
    /// pointed to), not the pointer address itself. For vector types, inner
    /// modifiers apply to the element type, not the vector container itself.
    ///
    /// ### C++ Const Pointer Semantics and Mapping
    /// WinMD pointer semantics are designed to mirror C++, so understanding C++
    /// pointer semantics can be helpful.
    ///
    /// - `const T*` (pointer to constant data)
    ///   - **C++**: The data at the memory address cannot be changed, but the pointer
    ///   itself can be reassigned to a different address.
    ///   - **WinMD**: An `IsConst` custom modifier precedes the element type `T`.
    ///   - **Swift**: Maps to an immutable `UnsafePointer<T>`.
    ///
    /// - `T* const` (constant pointer to mutable data)
    ///   - **C++**: The pointer is locked to a specific memory address, but the
    ///   data at the address can be modified.
    ///   - **WinMD**: An `IsConst` modifier precedes the pointer type itself
    ///   (rather than the element type).
    ///   - **Swift**: Maps to an `UnsafeMutablePointer<T>`. Because Swift
    ///   function parameters are inherently immutable `let` constants by
    ///   default, the pointer address is already locked, but the mutable
    ///   pointee requires an `UnsafeMutablePointer`.
    ///
    /// - Parameters:
    ///   - precedingModifiers: Preceding custom modifiers parsed from the
    ///   signature containing this type
    func swiftTypeName(precedingModifiers: [CustomMod]) throws -> String {
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
            
        case .genericInstance(let genericInstance):
            let typeName = String(MetadataDB.trimGenericArity(
                try genericInstance.type.name[...]
            ))
            let arguments = try GenericArgumentListSyntax {
                for arg in genericInstance.typeArgs {
                    GenericArgumentSyntax(argument: .type(
                        TypeSyntax(
                            stringLiteral: try arg.swiftTypeName(
                                precedingModifiers: []
                            )
                        )
                    ))
                }
            }
            return IdentifierTypeSyntax(
                name: .identifier(typeName),
                genericArgumentClause: GenericArgumentClauseSyntax(
                    arguments: arguments
                )
            ).description
            
        case .genericTypeParameter(let index):
            return "T\(index)"
            
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
