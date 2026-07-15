import WinMD

extension Constant.ConstantValue {
    var literalStringValue: String {
        switch self {
        case .int8(let v): String(v)
        case .uint8(let v): String(v)
        case .int16(let v): String(v)
        case .uint16(let v): String(v)
        case .int32(let v): String(v)
        case .uint32(let v): String(v)
        case .int64(let v): String(v)
        case .uint64(let v): String(v)
        case .float32(let v): String(v)
        case .float64(let v): String(v)
        
        // Wrap strings in quotes
        case .string(let v): "\"\(v)\""
        }
    }
}
