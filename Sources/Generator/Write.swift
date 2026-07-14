import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

func write(type: TypeDef) throws {
    let category = try type.category
    
    if type.flags.implementation.contains(.windowsRuntime) {
        // WinRT
        switch category {
        case .enum:
            try write(winRTEnum: type)
            
        case .delegate:
            print("WinRT delegate")
        case .struct:
            print("WinRT struct")
        case .attribute:
            // Attributes are looked up on other items
            print("WinRT attribute (ignored)")
            return
        case .class:
            print("WinRT class")
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
                    try write(win32method: method)
                }
                
                for field in try type.fields {
                    try write(win32field: field)
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

extension Constant.ConstantValue {
    var literalStringValue: String {
        switch self {
        case .int8(let v): String(v)
        case .uint8(let v): String(v)
        case .int16(let v): String(v)
        case .uint16(let v): String(v)
        case .int32(let v): String(v)
        case .uint32(let v): String(v)
        case .int64(let v): String(v)
        case .uint64(let v): String(v)
        case .float32(let v): String(v)
        case .float64(let v): String(v)
        
        // Wrap strings in quotes
        case .string(let v): "\"\(v)\""
        }
    }
}

extension Type {
    func swiftTypeName(precedingModifiers: [CustomMod] = []) throws -> String {
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
            let isConst = try precedingModifiers.contains { customMod in
                let type = try customMod.type
                return try type.namespace == "System.Runtime.CompilerServices" && type.name == "IsConst"
            }
            
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

enum EnumError: Error {
    case missingValueField
    case missingCaseConstant
}

// See ECMA-335 - §II.14.3 Enums
func write(winRTEnum type: TypeDef) throws {
    let name = try type.name
    let fields = try type.fields
    
    // An enum TypeDef has exactly one instance field, `value__`, which holds
    // the raw value. The type of that field defines the underlying type of the
    // enumeration. It is the first field.
    guard let valueField = fields.first else {
        throw EnumError.missingValueField
    }
    let signature = try valueField.signature
    let underlyingTypeName = try signature.type.swiftTypeName(
        precedingModifiers: signature.customModifiers
    )
    
    var cases = [(name: String, value: String)]()
    for field in fields {
        // All other fields are static and literal and declare the mapping of
        // the symbols of the enum to the underlying value
        guard field.flags.flags.contains(.literal),
              field.flags.flags.contains(.static),
              field.flags.flags.contains(.hasDefault) else {
            continue
        }
        
        guard let constant = try field.constant else {
            throw EnumError.missingCaseConstant
        }
        let value = try constant.value
        
        cases.append((try field.name, value.literalStringValue))
    }
    
    let decl: DeclSyntax
    
    let enumAttributes = try type.customAttributes
    if try hasAttribute(enumAttributes, namespace: "System", name: "FlagsAttribute") {
        decl = DeclSyntax(
            try StructDeclSyntax("struct \(raw: name): OptionSet") {
                try VariableDeclSyntax("let rawValue: \(raw: underlyingTypeName)")
                
                for item in cases {
                    try VariableDeclSyntax("static let \(raw: item.name) = Self(rawValue: \(raw: item.value))")
                }
            }
        )
    } else {
        decl = DeclSyntax(
            EnumDeclSyntax(name: .identifier(name)) {
                MemberBlockItemSyntax(decl: EnumCaseDeclSyntax {
                    for (name, value) in cases {
                        EnumCaseElementSyntax(
                            name: .identifier(name),
                            rawValue: InitializerClauseSyntax(value: ExprSyntax(stringLiteral: value))
                        )
                    }
                })
            }
        )
    }
    
    print(decl.formatted().description)
}

func write(win32method method: MethodDef) throws {
    let name = try method.name
    print("Win32 method: \(name)")
}

func write(win32field field: Field) throws {
    let name = try field.name
    print("Win32 field: \(name)")
}
