import BinaryParsing

enum ConstantError: Error {
    case invalidType
    case missingParent
}

public struct Constant {
    private let file: MetadataFile
    
    public let type: ConstantType
    private let parentIndex: CodedIndex<HasConstant.Tag>
    private let valueIndex: HeapIndex
    
    public enum ConstantType {
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
    
    public enum ConstantValue {
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
        get throws { try .init(in: file, at: parentIndex) }
    }
    
    static func rowRange(
        tag: HasConstant.Tag,
        forParent parentIndex: Index,
        in file: MetadataFile
    ) throws -> Range<Index> {
        let codedIndex = CodedIndex<HasConstant.Tag>(tag: tag, index: parentIndex)
        
        return try file.equalRange(searchingTable: .constant) { rowIndex in
            try Constant(in: file, at: rowIndex)
                .parentIndex
                .compare(to: codedIndex)
        }
    }
    
    public var value: ConstantValue {
        get throws {
            try file.withBlobSpan(at: valueIndex) { span in
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
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        
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
        
        guard let parentIndex = try CodedIndex<HasConstant.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.hasConstant
        ) else {
            throw ConstantError.missingParent
        }
        self.parentIndex = parentIndex
        
        self.valueIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .constant, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
