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
    let isFinalBlock = try UInt8(reading: &span, bitCount: 1) == 1
    // BTYPE
    guard let blockType = BlockType(rawValue: try UInt8(reading: &span, bitCount: 2)) else {
        throw DeflateError.invalidBlockType
    }
    span.align()
    
    switch blockType {
    case .noCompression:
        let length = try UInt16(reading: &span) // LEN
        let nlength = try UInt16(reading: &span) // NLEN, the one's complement of LEN
    
    case .fixedHuffman:
        print("Fixed huffman")
        
    case .dynamicHuffman:
        // HLIT
        let numLiteralLengthCodes = try Int(reading: &span, bitCount: 5) + HLITBase
        // HDIST
        let numDistanceCodes = try Int(reading: &span, bitCount: 5) + HDISTBase
        // HCLEN
        let numCodeLengthCodes = try Int(reading: &span, bitCount: 4) + HCLENBase
        
        let codeLengths = try Array(count: numCodeLengthCodes) {
            try Int(reading: &span, bitCount: 3)
        }
    }
}
