struct PInvokeAttributes {
    typealias RawValue = UInt16
    
    struct Flags: OptionSet {
        let rawValue: RawValue
        
        static let noMangle = Self(rawValue: 0x0001)
        static let supportsLastError = Self(rawValue: 0x0040)
    }
    
    enum CharacterSet: RawValue, Maskable {
        static let mask: RawValue = 0x0006
        
        case notSpec = 0x0000
        case ansi = 0x0002
        case unicode = 0x0004
        case auto = 0x0006
    }
    
    enum CallingConvention: RawValue, Maskable {
        static let mask: RawValue = 0x0700
        
        case platformApi = 0x0100
        case cDecl = 0x0200
        case stdCall = 0x0300
        case thisCall = 0x0400
        case fastCall = 0x0500
    }
    
    let flags: Flags
    let characterSet: CharacterSet
    let callingConvention: CallingConvention
    
    init?(rawValue: RawValue) {
        guard let characterSet = CharacterSet(masking: rawValue),
              let callingConvention = CallingConvention(masking: rawValue) else {
            return nil
        }
        self.characterSet = characterSet
        self.callingConvention = callingConvention
        self.flags = Flags(rawValue: rawValue)
    }
}
