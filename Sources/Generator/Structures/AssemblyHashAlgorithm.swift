enum AssemblyHashAlgorithm: UInt32, Maskable {
    // the bit masks we want
    static let mask: UInt32 = 0x8004

    // Each of the possible algorithms (mutually exclusive)
    case `none` = 0x0000
    case `reserved` = 0x8003
    case `sha1` = 0x8004

    // mask the raw value with the bit mask to get relevant bits
    init?(masking rawValue: UInt32) {
        switch rawValue {
        // cases to see which type of algorithm the AssemblyHashAlgorithm is
		case 0x0000: self = .none
        case 0x8003: self = .reserved
        case 0x8004: self = .sha1
        // if it doesn't fit any specified algorithm, return nil
        default: return nil
		
	}
    }

}