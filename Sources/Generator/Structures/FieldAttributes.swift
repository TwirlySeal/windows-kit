struct FieldAttributes {
    typealias RawValue = UInt16
    
    enum Access: RawValue, Maskable {
        static let mask: RawValue = 0x0007
        
        case compilerControlled = 0x0000
        case `private` = 0x0001
        case famANDAssem = 0x0002
        case assembly = 0x0003
        case family = 0x0004
        case famORAssem = 0x0005
        case `public` = 0x0006
    }
    
    struct Flags: OptionSet {
        let rawValue: RawValue
        
        static let `static` = Self(rawValue: 0x0010)
        static let initOnly = Self(rawValue: 0x0020)
        static let literal = Self(rawValue: 0x0040)
        static let notSerialised = Self(rawValue: 0x0080)
        static let specialName = Self(rawValue: 0x0200)
        
        static let pinvokeImpl = Self(rawValue: 0x2000)
        
        static let rtSpecialName = Self(rawValue: 0x0400)
        static let hasFieldMarshal = Self(rawValue: 0x1000)
        static let hasDefault = Self(rawValue: 0x8000)
        static let hasFieldRVA = Self(rawValue: 0x0100)
    }
    
    private let rawValue: RawValue
    
    let access: Access
    var flags: Flags {
        .init(rawValue: rawValue)
    }
    
    init?(rawValue: RawValue) {
        guard let access = Access(masking: rawValue) else {
            return nil
        }
        self.rawValue = rawValue
        self.access = access
    }
}
