import WinMD

extension RetType {
    func swiftTypeName() throws -> String {
        switch kind {
        case .type(let type):
            try type.swiftTypeName(
                precedingModifiers: self.customModifiers
            )
        case .byRef(_):
            fatalError("Unhandled return type kind: byRef")
        case .void:
            "Void"
        }
    }
}
