extension String {
    /// Convert a PascalCase string to camelCase
    func toCamelCase() -> String {
        guard !isEmpty else { return self }
        
        // Lowercase the first character
        let first = self.prefix(1).lowercased()
        let rest = self.dropFirst()
        
        return first + rest
    }
}
