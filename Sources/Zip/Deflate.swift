enum BlockType: UInt8 {
    case noCompression = 0b00
    case fixedHuffman = 0b01
    case dynamicHuffman = 0b10
}

enum DeflateError: Error {
    case invalidBlockType
}

extension Array {
    init<E: Error>(count: Int, element: () throws(E) -> Element) throws(E) {
        self.init()
        self.reserveCapacity(count)
        for _ in 0..<count {
            self.append(try element())
        }
    }
}

public func parseDeflate(span: inout BitSpan) throws {
    // BFINAL
    let isFinalBlock = try UInt8(span: &span, bitCount: 1) == 1
    // BTYPE
    guard let blockType = BlockType(rawValue: try UInt8(span: &span, bitCount: 2)) else {
        throw DeflateError.invalidBlockType
    }
    span.align()
    
    switch blockType {
    case .noCompression:
        let length = try UInt16(span: &span) // LEN
        let nlength = try UInt16(span: &span) // NLEN, the one's complement of LEN
    
    case .fixedHuffman:
        print("Fixed huffman")
        
    case .dynamicHuffman:
        // HLIT
        let nLiteralLengthCodes = try Int(span: &span, bitCount: 5) + HLITBase
        // HDIST
        let nDistanceCodes = try Int(span: &span, bitCount: 5) + HDISTBase
        // HCLEN
        let nCodeLengthCodes = try Int(span: &span, bitCount: 4) + HCLENBase
        
        let codeLengths = try Array(count: nCodeLengthCodes) {
            try Int(span: &span, bitCount: 3)
        }
    }
}

public struct CanonicalHuffmanDecoder {
    public let symbolCodes: [Int]

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
        
        // Step 3: Assign codes to all symbols
        var symbolCodes = Array(repeating: 0, count: lengths.count)
        for (symbolIndex, length) in lengths.enumerated() where length != 0 {
            // Assign the next available code for this length to the symbol
            symbolCodes[symbolIndex] = startingCodes[length]
            
            // Increment the starting code for this length so the next
            // symbol of the same length gets the next consecutive value
            startingCodes[length] += 1
        }
        
        self.symbolCodes = symbolCodes
    }
}

