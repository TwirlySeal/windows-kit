import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

func write(class type: TypeDef) throws {
    let className = try type.name
    
    let decl = try ClassDeclSyntax("class \(raw: className)") {
        for method in try type.methods {
            try makeMemberSyntax(for: method)
        }
    }
    
    print(decl.formatted().description)
}

@MemberBlockItemListBuilder
private func makeMemberSyntax(for method: MethodDef) throws -> MemberBlockItemListSyntax {
    let methodName = try method.name
    let paramRows = try method.params
    let signature = try method.signature
    let returnType = try signature.returnType.swiftTypeName()
    
    let getterPrefix = "get_"
    if methodName.starts(with: getterPrefix) {
        let propertyName = String(
            methodName.dropFirst(getterPrefix.count)
        ).toCamelCase()
        
        VariableDeclSyntax(
            .var,
            name: PatternSyntax(stringLiteral: propertyName),
            type: TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: returnType))
        )
    } else {
        let params = try FunctionParameterListSyntax {
            for (paramToken, paramRow) in zip(signature.params, paramRows) {
                FunctionParameterSyntax(
                    firstName: .identifier(try paramRow.name),
                    type: TypeSyntax(stringLiteral: try paramToken.type.swiftTypeName(
                        precedingModifiers: paramToken.customModifiers
                    ))
                )
            }
        }
        
        FunctionDeclSyntax(
            name: .identifier(methodName.toCamelCase()),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(parameters: params),
                returnClause: ReturnClauseSyntax(type: TypeSyntax(stringLiteral: returnType))
            )
        )
    }
}
