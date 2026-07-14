import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

enum EnumError: Error {
    case missingValueField
    case missingCaseConstant
}

// See ECMA-335 - §II.14.3 Enums
func write(enum type: TypeDef) throws {
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
