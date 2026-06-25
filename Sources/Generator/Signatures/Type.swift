import BinaryParsing

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
    
    indirect case array(Type, ArrayShape)
    case `class`(CodedIndex<TypeDefOrRef.Tag>)
    case genericInstance(GenericInstance)
    case genericTypeParameter(UInt32)
    case object
    indirect case pointer(Pointer)
    case string
    
    // Single-dimensional, zero-based array
    indirect case vector([CustomMod], Type)
    case valueType(CodedIndex<TypeDefOrRef.Tag>)
    
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
            guard let typeIndex = try CodedIndex<TypeDefOrRef.Tag>(rawValue: Int(rawValue)) else {
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
    
    enum TypeError: Error {
        case invalidGenericInst
        case invalidType
        case nullTypeIndex
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
            self = .array(type, shape)
            
        case ElementType.class:
            let rawValue = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            guard let type = try CodedIndex<TypeDefOrRef.Tag>(rawValue: Int(rawValue)) else {
                throw TypeError.nullTypeIndex
            }
            self = .class(type)
            
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
            self = .vector(customMods, type)
            
        case ElementType.valueType:
            let rawValue = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            guard let type = try CodedIndex<TypeDefOrRef.Tag>(rawValue: Int(rawValue)) else {
                throw TypeError.nullTypeIndex
            }
            self = .valueType(type)
            
        case ElementType.var:
            let number = try MetadataDB.parseCompressedUnsignedInteger(from: &span)
            self = .genericTypeParameter(number)
            
        default:
            throw TypeError.invalidType
        }
    }
    
    init(metadata: MetadataDB, at offset: Int) throws {
        self = try metadata.withBlobSpan(at: offset) { span in
            try Self(parsing: &span)
        }
    }
}
