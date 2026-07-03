import BinaryParsing

enum ConstantError: Error {
    case invalidType
    case missingParent
    case invalidParent
}

struct Constant {
    private let metadata: MetadataDB
    
    let type: ConstantType
    private let parentIndex: CodedIndex<HasConstant.Tag>
    private let valueIndex: UInt32
    
    enum ConstantType {
        case int8
        case uint8
        case int16
        case uint16
        case int32
        case uint32
        case int64
        case uint64
        case float32
        case float64
        case string
    }
    
    enum ConstantValue {
        case int8(Int8)
        case uint8(UInt8)
        case int16(Int16)
        case uint16(UInt16)
        case int32(Int32)
        case uint32(UInt32)
        case int64(Int64)
        case uint64(UInt64)
        case float32(Float)
        case float64(Double)
        case string(String)
    }
    
    var parent: HasConstant {
        get throws { try .init(metadata: metadata, index: parentIndex) }
    }
    
    var value: ConstantValue {
        get throws {
            try metadata.withBlobSpan(at: Int(valueIndex)) { span in
                switch self.type {
                case .int8:
                    .int8(try Int8(parsing: &span))
                    
                case .uint8:
                    .uint8(try UInt8(parsing: &span))
                    
                case .int16:
                    .int16(try Int16(parsingLittleEndian: &span))
                    
                case .uint16:
                    .uint16(try UInt16(parsingLittleEndian: &span))
                    
                case .int32:
                    .int32(try Int32(parsingLittleEndian: &span))
                    
                case .uint32:
                    .uint32(try UInt32(parsingLittleEndian: &span))
                    
                case .int64:
                    .int64(try Int64(parsingLittleEndian: &span))
                    
                case .uint64:
                    .uint64(try UInt64(parsingLittleEndian: &span))
                    
                case .float32:
                    .float32(try Float(parsingLittleEndian: &span))
                    
                case .float64:
                    .float64(try Double(parsingLittleEndian: &span))
                    
                case .string:
                    .string(try String(parsingUTF16: &span))
                }
            }
        }
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        self.type = switch try UInt8(parsing: &span) {
        case ElementType.i1:
            .int8
            
        case ElementType.u1:
            .uint8
            
        case ElementType.i2:
            .int16
            
        case ElementType.u2:
            .uint16
            
        case ElementType.i4:
            .int32
            
        case ElementType.u4:
            .uint32
            
        case ElementType.i8:
            .int64
            
        case ElementType.u8:
            .uint64
            
        case ElementType.r4:
            .float32
            
        case ElementType.r8:
            .float64
            
        case ElementType.string:
            .string
        
        default:
            throw ConstantError.invalidType
        }
        
        let parentValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.codedIndexSizes.hasConstant))
        guard let parentIndex = try CodedIndex<HasConstant.Tag>(rawValue: Int(parentValue)) else {
            throw ConstantError.missingParent
        }
        guard parentIndex.tag == .field else {
            throw ConstantError.invalidParent
        }
        self.parentIndex = parentIndex
        
        self.valueIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.heapSizes.blobSize)
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .constant, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
