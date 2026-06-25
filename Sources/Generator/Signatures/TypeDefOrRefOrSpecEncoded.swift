import BinaryParsing

struct TypeDefOrRefOrSpecEncoded {
    let table: Table
    let index: Index
    
    enum Table: UInt32 {
        case typeDef = 0
        case typeRef = 1
        case typeSpec = 2
    }
    
    enum TypeDefOrRefOrSpecEncodedError: Error {
        case invalidTable
        case missingIndex
    }
    
    init(parsing span: inout ParserSpan) throws {
        let rawValue = try MetadataDB.parseCompressedUnsignedInteger(span: &span)
        
        let tagBits = rawValue & 0b11 // bottom two bits
        guard let table = Table(rawValue: tagBits) else {
            throw TypeDefOrRefOrSpecEncodedError.invalidTable
        }
        self.table = table
        
        
        let indexBits = rawValue >> 2
        guard let index = Index(rawValue: indexBits) else {
            throw TypeDefOrRefOrSpecEncodedError.missingIndex
        }
        self.index = index
    }
}
