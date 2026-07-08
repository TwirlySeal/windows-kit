struct ParamAttributes: OptionSet {
    let rawValue: UInt16
    
    static let `in` = Self(rawValue: 0x0001)
    static let out = Self(rawValue: 0x0002)
    static let optional = Self(rawValue: 0x0010)
    static let hasDefault = Self(rawValue: 0x1000)
    static let hasFieldMarshal = Self(rawValue: 0x2000)
    static let unused = Self(rawValue: 0xcfe0)
}
