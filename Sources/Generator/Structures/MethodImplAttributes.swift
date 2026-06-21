struct MethodImplAttributes {
    typealias RawValue = UInt16
    
    enum CodeType: RawValue, Maskable {
        static let mask: RawValue = 0x0003
        
        case il = 0x0000
        case native = 0x0001
        case optil = 0x0002
        case runtime = 0x0003
    }
    
    enum Managed: RawValue, Maskable {
        static let mask: RawValue = 0x0004
        
        case unmanaged = 0x0004
        case managed = 0x0000
    }
    
    struct Flags: OptionSet {
        let rawValue: RawValue
        
        static let forwardRef = Self(rawValue: 0x0080)
        static let preserveSig = Self(rawValue: 0x0080)
        static let internalCall = Self(rawValue: 0x1000)
        static let synchronized = Self(rawValue: 0x0020)
        static let noInlining = Self(rawValue: 0x0008)
        static let maxMethodImplVal = Self(rawValue: 0xffff)
        static let noOptimisation = Self(rawValue: 0x0040)
    }
    
    private let rawValue: RawValue
    
    let codeType: CodeType
    let managed: Managed
    var flags: Flags {
        .init(rawValue: rawValue)
    }
    
    init?(rawValue: RawValue) {
        guard let codeType = CodeType(masking: rawValue),
              let managed = Managed(masking: rawValue) else {
            return nil
        }
        self.rawValue = rawValue
        self.codeType = codeType
        self.managed = managed
    }
}
