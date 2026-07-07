import BinaryParsing

struct MethodDefSig {
    let header: Header
    let returnType: RetType
    let params: [ParamToken]
    
    struct Header: RawRepresentable {
        typealias RawValue = UInt8
        
        enum CallingConvention: RawValue, Maskable {
            static let mask: UInt8 = 0b0001_1111
            
            case `default` = 0x00
//            case vararg = 0x05
//            case generic = 0x10
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
    
    private init(parsing span: inout ParserSpan) throws {
        self.header = try Header(parsing: &span)
        
        let paramCount = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
        self.returnType = try RetType(parsing: &span)
        
        self.params = try [ParamToken](count: Int(paramCount)) {
            try ParamToken(parsing: &span)
        }
    }
    
    init(in metadata: MetadataDB, at offset: HeapIndex) throws {
        self = try metadata.withBlobSpan(at: offset) { span in
            try Self(parsing: &span)
        }
    }
}
