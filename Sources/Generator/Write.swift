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

enum EnumError: Error {
    case missingValueField
    case missingCaseConstant
}

func write(winRTEnum type: TypeDef) throws {
    let name = try type.name
    let fields = try type.fields
    
    // An enum TypeDef has exactly one instance field, `value__`, which holds
    // the raw value. The type of that field defines the underlying type of the
    // enumeration. It is the first field.
    guard let valueField = fields.first else {
        throw EnumError.missingValueField
    }
    
    var cases = [EnumCaseElementSyntax]()
    for field in fields {
        guard field.flags.flags.contains(.literal) else {
            continue
        }
        
        guard let constant = try field.constant else {
            throw EnumError.missingCaseConstant
        }
        let value = try constant.value
        
        cases.append(
            EnumCaseElementSyntax(
                name: .identifier(try field.name),
                rawValue: InitializerClauseSyntax(
                    value: IntegerLiteralExprSyntax(integerLiteral: 1)
                )
            )
        )
    }
    
    let example = EnumDeclSyntax(
        name: .identifier(name),
        inheritanceClause: InheritanceClauseSyntax {
            InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("Int")))
        }
    ) {
        MemberBlockItemSyntax(decl: EnumCaseDeclSyntax {
            cases
        })
    }
    print(example.formatted().description)
}

func write(win32method method: MethodDef) throws {
    let name = try method.name
    print("Win32 method: \(name)")
}

func write(win32field field: Field) throws {
    let name = try field.name
    print("Win32 field: \(name)")
}
