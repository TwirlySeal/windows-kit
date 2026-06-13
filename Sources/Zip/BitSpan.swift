enum BitError: Error {
    case insufficientData
}

/// LSB reader modelled after ParserSpan from Swift Binary Parsing
public struct BitSpan: ~Copyable, ~Escapable {
    private let span: Span<UInt8>
    
    private var byteOffset: Int = 0
    /// The bit index within the current byte (0..<8)
    private var bitOffset: Int = 0
    
    @_lifetime(copy span)
    public init(span: Span<UInt8>) throws {
        guard !span.isEmpty else {
            throw BitError.insufficientData
        }
        self.span = span
    }
    
    var bitsLeft: Int {
        let bytesLeft = span.count - byteOffset
        return (bytesLeft * 8) - bitOffset
    }
    
    /// Jump to the start of the next byte
    mutating func align() {
        if bitOffset > 0 {
            bitOffset = 0
            byteOffset += 1
        }
    }
    
    mutating func read<T: FixedWidthInteger>(bitCount: Int) throws -> T {
        // `(1 << count) - 1` gives a bitmask for the bottom `count` bits
        // Example:
        // - If `count` is 3, `1 << 3` equals `0b00001000`.
        // - Subtracting 1 gives `0b00000111`
        //
        // `span[byteOffset] >> bitOffset` gives the current byte with
        // the bits we've already read shifted out
        
        assert(0...T.bitWidth ~= bitCount)
        guard bitsLeft >= bitCount else {
            throw BitError.insufficientData
        }
        
        let bitsLeftInCurrentByte = 8 - bitOffset
        
        // Fast path: All bits requested are within the current byte
        if bitsLeftInCurrentByte > bitCount {
            let mask: UInt8 = (1 << bitCount) &- 1
            let result = (span[byteOffset] >> bitOffset) & mask
            
            bitOffset += bitCount
            return T(truncatingIfNeeded: result)
        }
        
        var result: T = 0
        // Shifting a value by `bitsRead` shifts it to the left of the bits
        // we have already read, then we use a bitwise OR to combine it
        // with the current result
        var bitsRead = 0
        
        // Head: Consume all remaining bits in the current byte
        let headMask: UInt8 = (1 << bitsLeftInCurrentByte) &- 1
        result |= T(truncatingIfNeeded: (span[byteOffset] >> bitOffset) & headMask)
        
        bitsRead += bitsLeftInCurrentByte
        byteOffset += 1
        
        // Middle: Consume whole bytes at a time
        while bitCount - bitsRead >= 8 {
            result |= T(truncatingIfNeeded: span[byteOffset]) << bitsRead
            
            bitsRead += 8
            byteOffset += 1
        }
        
        // Tail: Consume any remaining bits from the final byte
        let remainingBits = bitCount - bitsRead
        if remainingBits > 0 {
            let tailMask: UInt8 = (1 << remainingBits) &- 1
            result |= T(truncatingIfNeeded: span[byteOffset] & tailMask) << bitsRead
            
            bitOffset = remainingBits // Stop partway through this byte
        } else {
            bitOffset = 0 // Landed exactly on a byte boundary
        }
        
        return T(result)
    }
}

extension FixedWidthInteger where Self : BitwiseCopyable {
    /// Create an integer by parsing a value of this type's size
    init(span: inout BitSpan, bitCount: Int = Self.bitWidth) throws {
        self = try span.read(bitCount: bitCount)
    }
}
