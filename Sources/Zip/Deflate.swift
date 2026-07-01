import Foundation

enum BlockType: UInt8 {
    case noCompression = 0b00
    case fixedHuffman = 0b01
    case dynamicHuffman = 0b10
}

enum DeflateError: Error {
    case invalidBlockType
    case corruptedLength
    case emptyCodeLengthTree
    case invalidRLE
    case invalidCodeLengthSymbol
    case emptyLiteralTree
    case unexpectedDistanceCode
    case invalidLiteralSymbol
    case invalidDistanceSymbol
    case invalidDistancePointer
}

let fixedLiteralDecoder = CanonicalHuffmanDecoder.fixedLiteralDecoder()

let fixedDistanceDecoder = CanonicalHuffmanDecoder.fixedDistanceDecoder()

public func parseDeflate(span: Span<UInt8>, uncompressedSize: Int) throws -> Data {
    var bitSpan = try BitSpan(span: span)
    
    return try Data(capacity: uncompressedSize) { outputSpan in
        var isFinalBlock = false
        while !isFinalBlock {
            isFinalBlock = try parseDeflateBlock(span: &bitSpan, output: &outputSpan)
        }
    }
}

func parseDeflateBlock(span: inout BitSpan, output: inout OutputSpan<UInt8>) throws -> Bool {
    // BFINAL
    let isFinalBlock = try UInt8(reading: &span, bitCount: 1) == 1
    // BTYPE
    guard let blockType = BlockType(rawValue: try UInt8(reading: &span, bitCount: 2)) else {
        throw DeflateError.invalidBlockType
    }
    
    switch blockType {
    case .noCompression:
        span.align()
        let length = try UInt16(reading: &span) // LEN
        let nlength = try UInt16(reading: &span) // NLEN, the one's complement of LEN
        guard length == ~nlength else {
            throw DeflateError.corruptedLength
        }
        
        let bytes = span.bytes.extracting(first: Int(length))
        try bytes.copy(output: &output)
        try span.seek(toRelativeByteOffset: Int(length))
        
    case .fixedHuffman:
        try processHuffmanBlock(
            span: &span,
            output: &output,
            literalDecoder: fixedLiteralDecoder,
            distanceDecoder: fixedDistanceDecoder
        )
        
    case .dynamicHuffman:
        // HLIT
        let numLiteralLengthCodes = try Int(reading: &span, bitCount: 5) + HLITBase
        // HDIST
        let numDistanceCodes = try Int(reading: &span, bitCount: 5) + HDISTBase
        // HCLEN
        let numCodeLengthCodes = try Int(reading: &span, bitCount: 4) + HCLENBase
        
        var codeLengths = [Int](repeating: 0, count: 19)
        for i in 0..<numCodeLengthCodes {
            let length = try Int(reading: &span, bitCount: 3)
            codeLengths[codeLengthOrder[i]] = length
        }
        
        guard let codeLengthTree = try CanonicalHuffmanDecoder(lengths: codeLengths) else {
            throw DeflateError.emptyCodeLengthTree
        }
        
        let totalNumCodes = numLiteralLengthCodes + numDistanceCodes
        let allLengths = try decodeCodeLengths(
            count: totalNumCodes,
            using: codeLengthTree,
            from: &span
        )
        
        let literalLengthLengths = Array(allLengths[0..<numLiteralLengthCodes])
        
        guard let literalDecoder = try CanonicalHuffmanDecoder(lengths: literalLengthLengths) else {
            throw DeflateError.emptyLiteralTree
        }
        
        let distanceLengths = Array(allLengths[numLiteralLengthCodes..<totalNumCodes])
        
        let distanceDecoder = try CanonicalHuffmanDecoder(lengths: distanceLengths)
        
        try processHuffmanBlock(
            span: &span,
            output: &output,
            literalDecoder: literalDecoder,
            distanceDecoder: distanceDecoder
        )
    }
    return isFinalBlock
}

func processHuffmanBlock(
    span: inout BitSpan,
    output: inout OutputSpan<UInt8>,
    literalDecoder: borrowing CanonicalHuffmanDecoder,
    distanceDecoder: CanonicalHuffmanDecoder?
) throws {
    while true {
        let symbol = try literalDecoder.decode(span: &span)
        
        switch symbol {
        case 0...255:
            output.append(UInt8(symbol))
            
        case 256:
            // End of block
            return
            
        case 257...285:
            // LZ77 length/distance pair
            guard let distanceDecoder else {
                throw DeflateError.unexpectedDistanceCode
            }
            
            let matchLength = try decodeMatchLength(symbol: symbol, from: &span)
            let distanceSymbol = try distanceDecoder.decode(span: &span)
            let matchDistance = try decodeMatchDistance(symbol: distanceSymbol, from: &span)
            
            guard matchDistance <= output.count else {
                throw DeflateError.invalidDistancePointer
            }
            
            // In Deflate, the match length can be greater than the match distance.
            // Example: Your output buffer currently contains 'abc'. The decoder
            // receives a pointer with matchDistance = 3 and matchLength = 6.
            //
            // You look 3 bytes back, which points to the a. You need to copy 6
            // bytes forward. How do you copy 6 bytes when you only have 3 available?
            //
            // You copy them one byte at a time. As you copy a, b, and c, they are
            // appended to the buffer, meaning they become available to be read again
            // for the next 3 bytes. The output naturally becomes 'abcabc'.
            
            let readStartIndex = output.count - matchDistance
            for i in 0..<matchLength {
                let byteToCopy = output[readStartIndex + i]
                output.append(byteToCopy)
            }
            
        default:
            // Symbols 286 and 287 are invalid
            throw DeflateError.invalidLiteralSymbol
        }
    }
}

// Run-Length Encoding
func decodeCodeLengths(count: Int, using tree: borrowing CanonicalHuffmanDecoder, from span: inout BitSpan) throws -> [Int] {
    var codeLengths = [Int]()
    codeLengths.reserveCapacity(count)
    
    while codeLengths.count < count {
        let symbol = try tree.decode(span: &span)
        
        switch symbol {
        case 0...15:
            // Literal code length
            codeLengths.append(symbol)
            
        case 16:
            // Repeat the previous code length 3 - 6 times
            guard let lastLength = codeLengths.last else {
                throw DeflateError.invalidRLE
            }
            let repeatCount = try Int(reading: &span, bitCount: 2) + 3
            codeLengths.append(contentsOf: [Int](repeating: lastLength, count: repeatCount))
            
        case 17:
            // Repeat a code length of 0 for 3 - 10 times
            let repeatCount = try Int(reading: &span, bitCount: 3) + 3
            codeLengths.append(contentsOf: [Int](repeating: 0, count: repeatCount))
            
        case 18:
            // Repeat a code length of 0 for 11 to 138 times
            let repeatCount = try Int(reading: &span, bitCount: 7) + 11
            codeLengths.append(contentsOf: [Int](repeating: 0, count: repeatCount))
        
        default:
            throw DeflateError.invalidCodeLengthSymbol
        }
    }
    return codeLengths
}

func decodeMatchLength(symbol: Int, from span: inout BitSpan) throws -> Int {
    guard 257...285 ~= symbol else {
        throw DeflateError.invalidLiteralSymbol
    }
    
    let (base, extra) = lengthCodeTable[symbol - 257]
    
    if extra > 0 {
        let extraBits = try Int(reading: &span, bitCount: Int(extra))
        return Int(base) + extraBits
    }
    
    return Int(base)
}

func decodeMatchDistance(symbol: Int, from span: inout BitSpan) throws -> Int {
    guard 0...29 ~= symbol else {
        throw DeflateError.invalidDistanceSymbol
    }
    
    let (base, extra) = distanceCodeTable[symbol]
    
    if extra > 0 {
        let extraBits = try Int(reading: &span, bitCount: Int(extra))
        return Int(base) + extraBits
    }
    
    return Int(base)
}
