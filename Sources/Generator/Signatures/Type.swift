import BinaryParsing

enum TypeError: Error {
    case invalidGenericInst
    case invalidType
    case nullTypeIndex
}

enum Type {
    case boolean
    case char
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
    case int
    case uint
    case object
    case string
    
    indirect case array(element: Type, shape: ArrayShape)
    case `class`(typeIndex: CodedIndex<TypeDefOrRef.Tag>)
    case `enum`(name: String)
    case genericInstance(GenericInstance)
    case genericTypeParameter(index: UInt32)
    indirect case pointer(Pointer)
    
    // Single-dimensional, zero-based array
    indirect case vector(modifiers: [CustomMod], element: Type)
    case valueType(typeIndex: CodedIndex<TypeDefOrRef.Tag>)
    
    struct GenericInstance {
        enum Kind {
            case `class`
            case valueType
        }
        
        let kind: Kind
        let typeIndex: CodedIndex<TypeDefOrRef.Tag>
        let typeArgs: [Type]
        
        init(parsing span: inout ParserSpan) throws {
            self.kind = switch try UInt8(parsing: &span) {
            case ElementType.class:
                .class
            case ElementType.valueType:
                .valueType
            default:
                throw TypeError.invalidGenericInst
            }
            
            let rawValue = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            guard let typeIndex = try CodedIndex<TypeDefOrRef.Tag>(rawValue: rawValue) else {
                throw TypeError.nullTypeIndex
            }
            self.typeIndex = typeIndex
            
            let genArgCount = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            self.typeArgs = try [Type](count: Int(genArgCount)) {
                try Type(parsing: &span)
            }
        }
    }
    
    struct Pointer {
        let customModifiers: [CustomMod]
        let pointee: Pointee
        
        enum Pointee {
            case type(Type)
            case void
        }
        
        init(parsing span: inout ParserSpan) throws {
            self.customModifiers = try CustomMod.parseZeroOrMore(from: &span)
            
            var copySpan = ParserSpan(span.bytes)
            if try UInt8(parsing: &copySpan) == ElementType.void {
                self.pointee = .void
                span = copySpan
            } else {
                self.pointee = .type(try Type(parsing: &span))
            }
        }
    }
    
    init(parsing span: inout ParserSpan) throws {
        switch try UInt8(parsing: &span) {
        case ElementType.boolean:
            self = .boolean
            
        case ElementType.char:
            self = .char
            
        case ElementType.i1:
            self = .int8
            
        case ElementType.u1:
            self = .uint8
            
        case ElementType.i2:
            self = .int16
            
        case ElementType.u2:
            self = .uint16
            
        case ElementType.i4:
            self = .int32
            
        case ElementType.u4:
            self = .uint32
            
        case ElementType.i8:
            self = .int64
            
        case ElementType.u8:
            self = .uint64
            
        case ElementType.r4:
            self = .float32
            
        case ElementType.r8:
            self = .float64
            
        case ElementType.i:
            self = .int
            
        case ElementType.u:
            self = .uint
            
        case ElementType.array:
            let type = try Type(parsing: &span)
            let shape = try ArrayShape(parsing: &span)
            self = .array(element: type, shape: shape)
            
        case ElementType.class:
            let rawValue = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            guard let type = try CodedIndex<TypeDefOrRef.Tag>(rawValue: rawValue) else {
                throw TypeError.nullTypeIndex
            }
            self = .class(typeIndex: type)
            
        case ElementType.genericInst:
            self = .genericInstance(try GenericInstance(parsing: &span))
            
        case ElementType.object:
            self = .object
            
        case ElementType.ptr:
            self = .pointer(try Pointer(parsing: &span))
            
        case ElementType.string:
            self = .string
            
        case ElementType.szArray:
            let customMods = try CustomMod.parseZeroOrMore(from: &span)
            let type = try Type(parsing: &span)
            self = .vector(modifiers: customMods, element: type)
            
        case ElementType.valueType:
            let rawValue = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            guard let type = try CodedIndex<TypeDefOrRef.Tag>(rawValue: rawValue) else {
                throw TypeError.nullTypeIndex
            }
            self = .valueType(typeIndex: type)
            
        case ElementType.var:
            let number = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            self = .genericTypeParameter(index: number)
            
        case ElementType.enum:
            // SERIALIZATION_TYPE_ENUM in custom attribute named argument format
            // (ECMA-335 §II.23.1.16): followed by a SerString of the enum type name.
            // Enums are always value types.
            self = .enum(name: try serString(parsing: &span))
            
        default:
            throw TypeError.invalidType
        }
    }
    
    init(metadata: MetadataDB, at offset: HeapIndex) throws {
        self = try metadata.withBlobSpan(at: offset) { span in
            try Self(parsing: &span)
        }
    }
}
