import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

func write(struct type: TypeDef) throws {
    let structName = try type.name
    let fields = try type.fields
    
    let decl = try StructDeclSyntax("struct \(raw: structName)") {
        for field in fields {
            let name = try field.name.toCamelCase()
            let signature = try field.signature
            let fieldType = try signature.type.swiftTypeName(
                precedingModifiers: signature.customModifiers
            )
            try VariableDeclSyntax("let \(raw: name): \(raw: fieldType)")
        }
    }
    
    print(decl.formatted().description)
}
