struct GenericParamAttributes {
    typealias RawValue = UInt16
    
    enum Variance: RawValue, Maskable {
        static let mask: RawValue = 0x0003
        
        case none = 0x0000
        
        // Disallowed cases:
        // case covariant = 0x0001
        // case contravariant = 0x0002
    }
    
    enum SpecialConstraint: RawValue, Maskable {
        static let mask: RawValue = 0x001C
        
        case referenceTypeConstraint = 0x0004
        case notNullableValueTypeConstraint = 0x0008
        case defaultConstructorConstraint = 0x0010
    }
    
    let variance: Variance
    let specialConstraint: SpecialConstraint
    
    init?(rawValue: RawValue) {
        guard let variance = Variance(masking: rawValue),
              let specialConstraint = SpecialConstraint(masking: rawValue)
        else {
            return nil
        }
        
        self.variance = variance
        self.specialConstraint = specialConstraint
    }
}
