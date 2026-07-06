import BinaryParsing

enum CustomAttribError: Error {
    case invalidProlog
    case invalidParamKind
    case invalidValueType
}

struct CustomAttrib {
    let arguments: [Argument]
    
    private init(metadata: MetadataDB, parsing span: inout ParserSpan, _ params: [ParamToken]) throws {
        guard try UInt16(parsingLittleEndian: &span) == 0x0001 else {
            throw CustomAttribError.invalidProlog
        }
        
        // Fixed (positional) arguments
        var arguments = [Argument]()
        arguments.reserveCapacity(params.count)
        for param in params {
            guard param.kind == .normal else {
                throw CustomAttribError.invalidParamKind
            }
            arguments.append(
                Argument(
                    name: "",
                    value: try Value(metadata: metadata, parsing: &span, type: param.type)
                )
            )
        }
        
        // Named arguments
        let numNamed = try UInt16(parsingLittleEndian: &span)
        for _ in 0..<numNamed {
            _ = try ArgumentKind(parsing: &span)
            let type = try Type(parsing: &span)
            let name = try serString(parsing: &span)
            let value = try Value(metadata: metadata, parsing: &span, type: type)
            
            arguments.append(
                Argument(
                    name: name,
                    value: value
                )
            )
        }
        
        self.arguments = arguments
    }
    
    init(metadata: MetadataDB, at offset: HeapIndex, params: [ParamToken]) throws {
        self = try metadata.withBlobSpan(at: offset) { span in
            try Self(metadata: metadata, parsing: &span, params)
        }
    }
    
    struct Argument {
        let name: String
        let value: Value
    }
    
    enum ArgumentKind: UInt8 {
        case field = 0x53
        case property = 0x54
    }
    
    enum Value {
        case boolean(Bool)
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
        case type(name: String)
        case enumValue(name: String, value: Int32)
        
        init(metadata: MetadataDB, parsing span: inout ParserSpan, type: Type) throws {
            switch type {
            case .boolean:
                self = .boolean(try UInt8(parsing: &span) == 1)
                
            case .int8:
                self = .int8(try Int8(parsing: &span))
                
            case .uint8:
                self = .uint8(try UInt8(parsing: &span))
                
            case .int16:
                self = .int16(try Int16(parsingLittleEndian: &span))
                
            case .uint16:
                self = .uint16(try UInt16(parsingLittleEndian: &span))
                
            case .int32:
                self = .int32(try Int32(parsingLittleEndian: &span))
                
            case .uint32:
                self = .uint32(try UInt32(parsingLittleEndian: &span))
                
            case .int64:
                self = .int64(try Int64(parsingLittleEndian: &span))
                
            case .uint64:
                self = .uint64(try UInt64(parsingLittleEndian: &span))
                
            case .float32:
                self = .float32(try Float(parsingLittleEndian: &span))
                
            case .float64:
                self = .float64(try Double(parsingLittleEndian: &span))
                
            case .string:
                self = .string(try serString(parsing: &span))
                
            case .class(let index):
                let (namespace, name) = try Self.getName(metadata: metadata, index: index)
                
                if namespace == "System" && name == "Type" {
                    self = .type(name: try serString(parsing: &span))
                } else {
                    self = .enumValue(
                        name: Self.getFullName(namespace, name),
                        value: try Int32(parsingLittleEndian: &span)
                    )
                }
                
            case .valueType(let index):
                let (namespace, name) = try Self.getName(metadata: metadata, index: index)
                self = .enumValue(
                    name: Self.getFullName(namespace, name),
                    value: try Int32(parsingLittleEndian: &span)
                )
                
            case .enum(let name):
                self = .enumValue(
                    name: name,
                    value: try Int32(parsingLittleEndian: &span)
                )
            
            default:
                throw CustomAttribError.invalidValueType
            }
        }
        
        static func getName(
            metadata: MetadataDB,
            index: CodedIndex<TypeDefOrRef.Tag>
        ) throws -> (namespace: String, name: String) {
            let namespace: String
            let name: String
            
            switch try TypeDefOrRef(metadata: metadata, index: index) {
            case .typeDef(let typeDef):
                namespace = try typeDef.namespace
                name = try typeDef.name
                
            case .typeRef(let typeRef):
                namespace = try typeRef.namespace
                name = try typeRef.name
                
            case .typeSpec(_):
                throw CustomAttribError.invalidValueType
            }
            
            return (namespace, name)
        }
        
        static func getFullName(_ namespace: String, _ name: String) -> String {
            if namespace.isEmpty {
                name
            } else {
                "\(namespace).\(name)"
            }
        }
    }
}

/// Parse a length-prefixed UTF-8 string
func serString(parsing span: inout ParserSpan) throws -> String {
    // Null strings (with PackedLen = 0xFF) do not occur in Windows Metadata
    let packedLen = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
    
    return try String(parsingUTF8: &span, count: Int(packedLen))
}
