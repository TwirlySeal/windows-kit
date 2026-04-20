struct MethodAttributes {
    enum MemberAccess: UInt16, Maskable {
        static let mask: UInt16 = 0x0007

        case compilerControlled = 0x0000
        case `private` = 0x0001
        case famANDAssem = 0x0002
        case assem = 0x0003
        case family = 0x0004
        case famORAssem = 0x0005
        case `public` = 0x0006
    }

    // How wrong does this look? 
    // I wrote it with OptionSet since 'static' and 'final' are not mutually exclusive keywords.
    // Meanwhile, I also wrote it as a Maskable as it has 'vtableLayoutMask' that retrieves vtable atributes
    // Furthermore, there cannot be a static virutal function, 
    struct VTableLayout: OptionSet, Maskable {
               let rawValue: UInt16
        static let mask: UInt16 = 0x0100

        static let `static` = Self(rawValue: 0x0010)
        static let `final` = Self(rawValue: 0x0020)
        static let virtual = Self(rawValue: 0x0040)
        static let hideBySig = Self(rawValue: 0x0080)
    }

    // I don't know what this enum should be called
    // So I'm calling it 'VTableSlotAllocation'
    // Since this slot is responsible for how a slot is allocated for a method
    enum VTableSlotAllocation: UInt16 {
        case reuseSlot = 0x0000
        case newSlot = 0x0100
    }

    struct OverrideAttributes: OptionSet {
        let rawValue: UInt16

        // I know that 'abstract' methods must be overriden, and 'strict' methods can only be overriden if accessible
        // But I also heard that abstract methods cannot be private
        // So I feel like this is a good implementation for methods that can be overriden
        static let strict = Self(rawValue: 0x0200)
        static let abstract = Self(rawValue: 0x0400)
        static let specialName = Self(rawValue: 0x0800)
    }

    struct InteropAttributes: OptionSet {
        let rawValue: UInt16
        
        static let pInvokeImpl = Self(rawValue: 0x2000)
        static let unmanagedExport = Self(rawValue: 0x0008)
    }

    struct AdditionalFlags: OptionSet {
        let rawValue: UInt16
        
        static let rtSpecialName = Self(rawValue: 0x1000)
        static let hasSecurity = Self(rawValue: 0x4000)
        static let requireSecObject = Self(rawValue: 0x8000)
    }
}