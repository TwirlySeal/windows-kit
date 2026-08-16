import WinMD
import SwiftSyntax
import SwiftSyntaxBuilder

enum ClassError: Error {
    case disallowedTypeSpec
    case missingBaseType
}

func write(class type: TypeDef, metadata: MetadataDB) throws {
    let className = try type.name
    
    var interfaceImpls = try type.interfaceImpls
    var currentDef: TypeDef = type
    
    // Handle interface impls inherited from base classes (WinRT composable classes)
    baseLoop: while true {
        switch try currentDef.extends {
        case .typeDef(let typeDef):
            currentDef = typeDef
            
        case .typeRef(let typeRef):
            let namespace = try typeRef.namespace
            let name = try typeRef.name
            
            // System.Object is an external .NET type, so it will never
            // appear in WinMD files (and therefore the MetadataDB).
            if namespace == "System" && name == "Object" {
                break baseLoop
            }
            
            currentDef = try metadata.findTypeDef(
                namespace: namespace,
                name: name
            )
            
        case .typeSpec:
            throw ClassError.disallowedTypeSpec
            
        case .none:
            // WinRT classes should always have an inheritance chain up to System.Object
            throw ClassError.missingBaseType
        }
        
        interfaceImpls.append(contentsOf: try currentDef.interfaceImpls)
    }
    
    struct Interface {
        let impl: InterfaceImpl
        let name: String
        let isDefault: Bool
        let isExclusive: Bool
    }
    
    var interfaces = [Interface]()
    for impl in interfaceImpls {
        let isDefault = try hasAttribute(
            impl.customAttributes,
            namespace: "Windows.Foundation.Metadata",
            name: "DefaultAttribute"
        )
        
        let name: String
        let interfaceDef: TypeDef
        switch try impl.interface {
        case .typeDef(let typeDef):
            name = try typeDef.name
            interfaceDef = typeDef
            
        case .typeRef(let typeRef):
            name = try typeRef.name
            interfaceDef = try metadata.findTypeDef(
                namespace: typeRef.namespace,
                name: name
            )
        case .typeSpec:
            throw ClassError.disallowedTypeSpec
        }
        
        let isExclusive = try hasAttribute(
            try interfaceDef.customAttributes,
            namespace: "Windows.Foundation.Metadata",
            name: "ExclusiveToAttribute"
        )
        
        interfaces.append(Interface(
            impl: impl,
            name: name,
            isDefault: isDefault,
            isExclusive: isExclusive
        ))
    }
    
    let decl = try ClassDeclSyntax(
        name: .identifier(className),
        inheritanceClause: InheritanceClauseSyntax {
            for interface in interfaces where !interface.isExclusive {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: interface.name))
            }
        }
    ) {
        for method in try type.methods {
            try makeMemberSyntax(for: method)
        }
    }
    
    print(decl.formatted().description)
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
