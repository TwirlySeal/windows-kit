enum ElementType {
    static let void: UInt8 = 0x01
    static let boolean: UInt8 = 0x02
    static let char: UInt8 = 0x03
    
    // i = signed integer
    // u = unsigned integer
    // followed by size in number of bytes
    static let i1: UInt8 = 0x04
    static let u1: UInt8 = 0x05
    
    static let i2: UInt8 = 0x06
    static let u2: UInt8 = 0x07
    
    static let i4: UInt8 = 0x08
    static let u4: UInt8 = 0x09
    
    static let i8: UInt8 = 0x0a
    static let u8: UInt8 = 0x0b
    
    // Real numbers (floating-point)
    static let r4: UInt8 = 0x0c // float
    static let r8: UInt8 = 0x0d // double
    
    static let string: UInt8 = 0x0e
    static let ptr: UInt8 = 0x0f // Followed by type
    static let byRef: UInt8 = 0x10 // Followed by type
    static let valueType: UInt8 = 0x11 // Followed by TypeDef or TypeRef token
    static let `class`: UInt8 = 0x12 // Followed by TypeDef or TypeRef token
    
    // Generic parameter in a generic type definition,
    // represented as number (compressed unsigned integer)
    static let `var`: UInt8 = 0x13
    
    // type rank boundsCount bound1 ...
    // loCount lo1 ...
    static let array: UInt8 = 0x14
    
    // Generic type instantiation. Followed by
    // type type-arg-count type-1 ... type-n
    static let genericInst: UInt8 = 0x15
    
    // Platform width integers
    static let i: UInt8 = 0x18 // System.IntPtr
    static let u: UInt8 = 0x19 // System.UIntPtr
    
    static let object: UInt8 = 0x1c // System.Object
    static let szArray: UInt8 = 0x1d // Single-dim array with 0 lower bound
    
    // Required modifier : followed by a
    // TypeDef or TypeRef token
    static let cmodReqd: UInt8 = 0x1f
    
    // Optional modifier : followed by a
    // TypeDef or TypeRef token
    static let cmodOpt: UInt8 = 0x20
    
    // Used in custom attributes to specify an enum
    static let `enum`: UInt8 = 0x55
}
