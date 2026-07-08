import BinaryParsing

struct ArrayShape {
    /// Number of dimensions in the array
    let rank: UInt32
    let sizes: [UInt32]
    let lowerBounds: [UInt32]
    
    enum ArrayShapeError: Error {
        case invalidRank
    }
    
    init(parsing span: inout ParserSpan) throws {
        self.rank = try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        guard rank >= 1 else {
            throw ArrayShapeError.invalidRank
        }
        
        let numSizes = try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        self.sizes = try [UInt32](count: Int(numSizes)) {
            try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        }
        
        let numLoBounds = try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        self.lowerBounds = try [UInt32](count: Int(numLoBounds)) {
            try MetadataFile.parseCompressedUnsignedInteger(from: &span)
        }
    }
}
