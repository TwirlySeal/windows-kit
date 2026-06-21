struct MethodAttributes {
    typealias RawValue = UInt16
    
    enum MemberAccess: RawValue, Maskable {
        static let mask: RawValue = 0x0007
        
        case compilerControlled = 0x0000
        case `private` = 0x0001
        case famANDAssem = 0x0002
        case assem = 0x0003
        case family = 0x0004
        case famORAssem = 0x0005
        case `public` = 0x0006
    }
    
    struct Flags: OptionSet {
        let rawValue: RawValue
        
        static let `static` = Self(rawValue: 0x0010)
        static let `final` = Self(rawValue: 0x0020)
        static let virtual = Self(rawValue: 0x0040)
        static let hideBySig = Self(rawValue: 0x0080)
        
        static let strict = Self(rawValue: 0x0200)
        static let abstract = Self(rawValue: 0x0400)
        static let specialName = Self(rawValue: 0x0800)
        
        // Interop attributes
        static let pinvokeImpl = Self(rawValue: 0x2000)
        static let unmanagedExport = Self(rawValue: 0x0008)
        
        // Additional flags
        static let rtSpecialName = Self(rawValue: 0x1000)
        static let hasSecurity = Self(rawValue: 0x4000)
        static let requireSecObject = Self(rawValue: 0x8000)
    }
    
    enum VtableLayout: RawValue, Maskable {
        static let mask: RawValue = 0x0100
        
        case reuseSlot = 0x0000
        case newSlot = 0x0100
    }
    
    private let rawValue: RawValue
    
    let memberAccess: MemberAccess
    var flags: Flags {
        .init(rawValue: rawValue)
    }
    let vtableLayout: VtableLayout
    
    init?(rawValue: RawValue) {
        guard let memberAccess = MemberAccess(masking: rawValue),
              let vtableLayout = VtableLayout(masking: rawValue)
        else {
            return nil
        }
        self.rawValue = rawValue
        self.memberAccess = memberAccess
        self.vtableLayout = vtableLayout
    }
}
