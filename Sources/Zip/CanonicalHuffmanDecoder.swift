struct CanonicalHuffmanDecoder {
    private static let chunkBits = 9
    private static let numChunks = 1 << chunkBits
    
    // Because we read in fixed size chunks, `bitLength` says how long the
    // code is and the remaining bits are ignored
    private enum TableEntry {
        case empty
        // Deflate symbol alphabets have a maximum of 286
        // Max bit length is 15
        case symbol(value: UInt16, bitLength: UInt8)
        case secondaryTable(offset: UInt16, bitCount: UInt8)
    }
    
    // In Huffman coding, more common symbols get shorter codes and conversely
    // less common symbols get longer codes. This gives better compression ratios.
    // In this decoder, more common symbols go in a fast primary table
    // and less common symbols go in a slower secondary table.
    
    private let primaryTable: [TableEntry]
    private let secondaryTable: [TableEntry]

    public init(lengths: [Int], maxLength: Int) {
        // Step 1: Count the number of codes for each code length
        // In a binary tree, the number of bits in a code is its depth.
        // We are counting how many leaves (symbols) terminate at each level.
        
        // Sized to `maxLength + 1` so we can use the lengths as indices
        var lengthFrequency = Array(repeating: 0, count: maxLength + 1)
        for length in lengths {
            // A length of 0 means the symbol is not used,
            // so we ignore it
            if length > 0 {
                lengthFrequency[length] += 1
            }
        }
        
        // Step 2: Find the numerical value of the smallest code for each
        // code length
        // Goal: Find the leftmost binary pattern for each level of the tree.
        // We traverse the tree level by level (depth 1 to `maxLength`).
        
        /// The starting value for the previous level
        var code = 0
        var startingCodes = Array(repeating: 0, count: maxLength + 1)
        for bits in 1...maxLength {
            code = (code + lengthFrequency[bits - 1]) << 1
            startingCodes[bits] = code
        }
        
        // Step 3: Assign codes to all symbols and build lookup tables
        
        // We initialize the primary table with empty placeholders so we can
        // assign directly to specific indices.
        var primaryTable = Array(repeating: TableEntry.empty, count: Self.numChunks)
        var secondaryTable = [TableEntry]()
        
        for (symbolIndex, length) in lengths.enumerated() where length != 0 {
            // Assign the next available code for this length to the symbol
            let canonicalCode = startingCodes[length]
            
            // Increment the starting code for this length so the next
            // symbol of the same length gets the next consecutive value
            startingCodes[length] += 1
            
            // Reverse bits to match LSB-first bitstream reading
            let reversedCode = Self.reverseBits(canonicalCode)
            
            if length <= Self.chunkBits {
                // Short code: Fits entirely in the primary table
                
                // Fill all 9-bit slots that start with this bit pattern
                let step = 1 << length
                
                for index in stride(from: reversedCode, to: Self.numChunks, by: step) {
                    primaryTable[index] = .symbol(value: UInt16(symbolIndex), bitLength: UInt8(length))
                }
            } else {
                // Long code: Requires a secondary table lookup
                
                // The first 9 bits read from the stream form our prefix (primary table index)
                let prefix = reversedCode & (Self.numChunks - 1)
                
                // The remaining bits form the suffix (secondary table index)
                let suffix = reversedCode >> Self.chunkBits
                let suffixLength = length - Self.chunkBits
                
                let offset: Int
                let excessBits = maxLength - Self.chunkBits
                let tableSize = 1 << excessBits
                
                // Check if we've already created a secondary table for this 9-bit prefix.
                // No Huffman code is a prefix of another. But because we are slicing the
                // bitstream at a fixed 9-bit point, many of the longer, deeper codes
                // will share the same 9-bit root before branching off in later bits
                if case .secondaryTable(let existingOffset, _) = primaryTable[prefix] {
                    offset = Int(existingOffset)
                } else {
                    // Allocate a new secondary table block
                    offset = secondaryTable.count
                    secondaryTable.append(contentsOf: Array(repeating: .empty, count: tableSize))
                    primaryTable[prefix] = .secondaryTable(offset: UInt16(offset), bitCount: UInt8(excessBits))
                }
                
                // Fill all slots in the overflow chunk that match the remaining bit pattern
                let step = 1 << suffixLength
                for index in stride(from: offset + suffix, to: offset + tableSize, by: step) {
                    secondaryTable[index] = .symbol(value: UInt16(symbolIndex), bitLength: UInt8(length))
                }
            }
        }
        
        self.primaryTable = primaryTable
        self.secondaryTable = secondaryTable
    }
    
    private static func reverseBits(_ value: Int) -> Int {
        var result = 0
        var v = value
        for _ in 0..<Int.bitWidth {
            result = (result << 1) | (v & 1)
            v >>= 1
        }
        return result
    }
}
