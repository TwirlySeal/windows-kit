import WinMD

extension RetType {
    /// Generates the equivalent Swift type name for this WinMD return type
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
