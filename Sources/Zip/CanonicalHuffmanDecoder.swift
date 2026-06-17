enum HuffmanError: Error {
    case incompleteTree
}

struct CanonicalHuffmanDecoder {
    private static let chunkBits = 9
    private static let numChunks = 1 << chunkBits // 512
    
    private enum TableEntry {
        // Empty placeholders are used to initialise tables so we can
        // assign directly to specific indices.
        case empty
        // Deflate symbol alphabets have a maximum of 286
        // Max code length is 15
        case symbol(value: UInt16, bitLength: UInt8)
        case secondaryTable(offset: UInt16, maxSuffixBits: UInt8)
    }
    
    // Direct lookups for codes <= 9 bits
    private let primaryTable: [512 of TableEntry]
    // Overflow lookup for codes > 9 bits
    private let secondaryTable: [[TableEntry]]

    public init?(lengths: [Int]) throws {
        // 1. Count the number of codes for each code length
        // In a binary tree, the number of bits in a code is its depth.
        // We are counting how many leaves (symbols) terminate at each level.
        
        // Maximum code length + 1 so lengths can be used as indices
        var lengthFrequency = [16 of Int](repeating: 0)
        var minLength = 0, maxLength = 0
        
        for length in lengths {
            // A length of 0 means the symbol is not used,
            // so we ignore it
            if length == 0 {
                continue
            }
            if minLength == 0 || length < minLength {
                minLength = length
            }
            if length > maxLength {
                maxLength = length
            }
            lengthFrequency[length] += 1
        }
        
        if maxLength == 0 {
            // Empty tree
            return nil
        }
        
        // 2. Find the numerical value of the smallest code for each
        // code length
        // This gives the leftmost binary pattern for each level of the tree.
        
        // The starting value for the previous level
        var code = 0
        var startingCodes = [16 of Int](repeating: 0)
        
        // By starting the loop at `minLength` rather than 1, we skip iterating over
        // shorter bit-lengths that have a count of zero
        for bits in minLength...maxLength {
            code <<= 1
            startingCodes[bits] = code
            code += lengthFrequency[bits]
        }
        
        let prefixSpaceFullyConsumed = (code == (1 << maxLength))
        // A normal binary tree requires at least two symbols to split a branch
        // but Deflate allows a "degenerate" case: a tree with only one symbol.
        // This enables compressing single character files efficiently.
        let isValidDegenerateTree = (code == 1 && maxLength == 1)
        
        if !prefixSpaceFullyConsumed && !isValidDegenerateTree {
            throw HuffmanError.incompleteTree
        }
        
        var primaryTable = [512 of TableEntry](repeating: .empty)
        var secondaryTable: [[TableEntry]]
        
        // 3. Pre-allocate secondary tables if any codes exceed 9 bits
        if maxLength > Self.chunkBits {
            let numLinks = 1 << (maxLength - Self.chunkBits)
            
            // How many Level 1 entries are dedicated to short codes
            let overflowStartIndex = startingCodes[Self.chunkBits+1] >> 1
            
            secondaryTable = [[TableEntry]](
                repeating: [],
                count: Self.numChunks - overflowStartIndex
            )
            
            for chunkIndex in overflowStartIndex..<Self.numChunks {
                // Deflate reads bits least-significant bit (LSB) first.
                // Canonical Huffman assigns codes MSB first.
                // We reverse the bits so the lookup table matches the incoming stream's bit-order.
                let reverseIndex = Self.reverseBits(chunkIndex, bitCount: Self.chunkBits)
//                let reverseIndex = reversedBits >> (16 - Self.chunkBits)
                
                let overflowOffset = chunkIndex - overflowStartIndex
                
                primaryTable[reverseIndex] = .secondaryTable(
                    offset: UInt16(overflowOffset),
                    maxSuffixBits: 0
                )
                
                secondaryTable[overflowOffset] = [TableEntry](
                    repeating: .empty,
                    count: numLinks
                )
            }
        } else {
            secondaryTable = []
        }
        
        // 4. Assign codes to all symbols and build lookup tables
        for (symbolIndex, length) in lengths.enumerated() {
            if length == 0 {
                continue
            }
            // Assign the next available code for this length to the symbol
            let canonicalCode = startingCodes[length]
            
            // Increment the starting code for this length so the next
            // symbol of the same length gets the next consecutive value
            startingCodes[length] += 1
            
            // Reverse bits to match LSB-first bitstream reading
            let reversedCode = Self.reverseBits(canonicalCode, bitCount: length)
            
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
                
                let excessBits = maxLength - Self.chunkBits
                let tableSize = 1 << excessBits
                
                // Extract the offset for the secondary table that was pre-allocated in Step 3
                guard case let .secondaryTable(offset, currentSuffixBits) = primaryTable[prefix] else {
                    // This is a sanity check. If the tree is valid, the pre-allocation
                    // step guarantees this slot already points to a secondary table.
                    throw HuffmanError.incompleteTree
                }
                
                if suffixLength > currentSuffixBits {
                    primaryTable[prefix] = .secondaryTable(
                        offset: offset,
                        maxSuffixBits: UInt8(suffixLength)
                    )
                }
                
                // Fill all slots in the secondary table that start with this suffix
                let step = 1 << suffixLength
                for index in stride(from: suffix, to: tableSize, by: step) {
                    secondaryTable[Int(offset)][index] = .symbol(
                        value: UInt16(symbolIndex),
                        bitLength: UInt8(length)
                    )
                }
            }
        }
        
        self.primaryTable = primaryTable
        self.secondaryTable = secondaryTable
    }
    
    private static func reverseBits(_ value: Int, bitCount: Int) -> Int {
        var result = 0
        var v = value
        for _ in 0..<bitCount {
            result = (result << 1) | (v & 1)
            v >>= 1
        }
        return result
    }
    
    func decode(span: inout BitSpan) throws -> Int {
        let chunk = try Int(peekingAtMost: &span, bitCount: Self.chunkBits)
        
        switch self.primaryTable[chunk] {
        case .symbol(let value, let bitLength):
            // Short code
            try span.seek(toRelativeBitOffset: Int(bitLength))
            return Int(value)
            
        case .secondaryTable(let offset, let maxSuffixBits):
            // Long code
            try span.seek(toRelativeBitOffset: Self.chunkBits)
            
            let suffix = try Int(peekingAtMost: &span, bitCount: Int(maxSuffixBits))
            
            switch self.secondaryTable[Int(offset)][suffix] {
            case .symbol(let value, let bitLength):
                let remainingBits = Int(bitLength) - Self.chunkBits
                try span.seek(toRelativeBitOffset: remainingBits)
                return Int(value)

            default:
                throw HuffmanError.incompleteTree
            }
            
        case .empty:
            throw HuffmanError.incompleteTree
        }
    }
    
    static func fixedLiteralDecoder() -> Self {
        var lengths = [Int](repeating: 0, count: 288)
        
        for i in 0...143 {
            lengths[i] = 8
        }
        for i in 144...255 {
            lengths[i] = 9
        }
        for i in 256...279 {
            lengths[i] = 7
        }
        for i in 280...287 {
            lengths[i] = 8
        }
        return try! self.init(lengths: lengths)!
    }
    
    static func fixedDistanceDecoder() -> Self {
        let lengths = [Int](repeating: 5, count: 32)
        return try! self.init(lengths: lengths)!
    }
}
