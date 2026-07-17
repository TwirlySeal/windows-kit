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

enum MethodError: Error {
    case paramCountMismatch
}

private func makeMemberSyntax(for method: MethodDef) throws -> MemberBlockItemListSyntax {
    let methodName = try method.name
    let paramRows = try method.params
    let signature = try method.signature
    let returnType = try signature.returnType.swiftTypeName()
    
    var params = [(name: String, type: String)]()
    for (paramToken, paramRow) in zip(signature.params, paramRows) {
        // A Sequence value of 0 refers to the owner method’s return type
        // Its parameters are then numbered from 1 onwards
        //
        // The Param row for the return type exists so that custom attributes
        // can be applied to it, but we do not need them
        //
        // Successive rows of the Param table that are owned by the same method
        // shall be ordered by increasing Sequence value
        //
        // Gaps in the sequence are allowed by ECMA-335 but not by Windows
        // Metadata
        if paramRow.sequence == 0 {
            continue
        }
        params.append((
            name: try paramRow.name,
            type: try paramToken.type.swiftTypeName(
                precedingModifiers: paramToken.customModifiers
            )
        ))
    }
    
    return MemberBlockItemListSyntax {
        // The associated 'MethodSemantics' table row for this MethodDef row should
        // also have the 'Getter' flag set in the 'Semantics' column, but this is
        // not enforced
        let getterPrefix = "get_"
        if method.flags.flags.contains(.specialName),
           methodName.starts(with: getterPrefix) {
            let propertyName = String(
                methodName.dropFirst(getterPrefix.count)
            ).toCamelCase()
            
            VariableDeclSyntax(
                .var,
                name: PatternSyntax(stringLiteral: propertyName),
                type: TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: returnType))
            )
        } else {
            let params = FunctionParameterListSyntax {
                for param in params {
                    FunctionParameterSyntax(
                        firstName: .identifier(param.name),
                        type: TypeSyntax(stringLiteral: param.type)
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
}
