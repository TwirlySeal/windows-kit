import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

enum EnumError: Error {
    case missingValueField
    case missingCaseConstant
}

// See ECMA-335 - §II.14.3 Enums
// and ECMA-335 - §I.8.5.2 Assemblies and scoping
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
        
        cases.append((try field.name.toCamelCase(), value.literalStringValue))
    }
    
    let decl: DeclSyntax
    
    // If an enum has the `System.FlagsAttribute` attribute, it is actually a
    // set of named bit flags that can be combined to generate an unnamed value.
    let enumAttributes = try type.customAttributes
    if try hasAttribute(enumAttributes, namespace: "System", name: "FlagsAttribute") {
        decl = DeclSyntax(
            StructDeclSyntax(
                name: .identifier(name),
                inheritanceClause: InheritanceClauseSyntax {
                    InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "OptionSet"))
                }
            ) {
                VariableDeclSyntax(
                    .let,
                    name: PatternSyntax(stringLiteral: "rawValue"),
                    type: TypeAnnotationSyntax(
                        type: TypeSyntax(stringLiteral: underlyingTypeName)
                    )
                )
                
                for item in cases {
                    VariableDeclSyntax(
                        modifiers: DeclModifierListSyntax(arrayLiteral:
                            DeclModifierSyntax(name: .keyword(.static))
                        ),
                        .let,
                        name: PatternSyntax(stringLiteral: item.name),
                        initializer: InitializerClauseSyntax(value: FunctionCallExprSyntax(
                            callee: DeclReferenceExprSyntax(baseName: .keyword(.Self))
                        ) {
                            LabeledExprSyntax(
                                label: .identifier("rawValue"),
                                colon: .colonToken(),
                                expression: ExprSyntax(stringLiteral: item.value)
                            )
                        })
                    )
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
