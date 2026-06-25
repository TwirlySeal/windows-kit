import BinaryParsing

struct MethodDefSig {
    let header: MethodHeader
    let returnType: RetType
    let params: [ParamToken]
    
    private init(parsing span: inout ParserSpan) throws {
        self.header = try MethodHeader(parsing: &span)
        
        let paramCount = try MetadataDB.parseCompressedUnsignedInteger(span: &span)
        self.returnType = try RetType(parsing: &span)
        
        self.params = try [ParamToken](count: Int(paramCount)) {
            try ParamToken(parsing: &span)
        }
    }
    
    init(metadata: MetadataDB, at offset: Int) throws {
        self = try metadata.withBlobSpan(at: offset) { span in
            try Self(parsing: &span)
        }
    }
}

struct MethodHeader: RawRepresentable {
    typealias RawValue = UInt8
    
    enum CallingConvention: RawValue, Maskable {
        static let mask: UInt8 = 0b0001_1111
        
        case `default` = 0x00
    }
    
    struct Flags: OptionSet {
        let rawValue: RawValue
        
        static let hasThis = Self(rawValue: 0x20)
        static let explicitThis = Self(rawValue: 0x40)
    }
    
    let callingConvention: CallingConvention
    let rawValue: RawValue
    
    var flags: Flags {
        .init(rawValue: rawValue)
    }
    
    init?(rawValue: RawValue) {
        guard let callingConvention = CallingConvention(masking: rawValue) else {
            return nil
        }
        self.callingConvention = callingConvention
        self.rawValue = rawValue
    }
}
