import Foundation
import BinaryParsing

/// Manages the binary data of a metadata file and information needed to parse
/// table rows. Lightweight view structs representing table rows are parsed on
/// demand, and hold a reference to this class for indices into other tables.
/// This allows them to make the index private and provide computed properties
/// that parse the linked table row when it is accessed.
///
/// View structs go in the Tables folder
final class MetadataDB {
    private let data: Data
    let ranges: MetadataInfo
    
    init(data: Data) throws {
        self.data = data
        self.ranges = try data.withParserSpan { try MetadataInfo(parsing: &$0) }
    }
    
    /// Parse one row of a table
    func withRowSpan<T>(in table: TableKind, rowIndex: Int, _ body: (inout ParserSpan) throws -> T) throws -> T {
        try data.withParserSpan { span in
            guard let range = ranges.tables[table.rawValue] else {
                throw ParsingError()
            }
            try span.seek(toRange: range)
            try span.seek(toRelativeOffset: ranges.strides[table.rawValue] * rowIndex)
            return try body(&span)
        }
    }
    
    /// Read from the string heap
    func string(at offset: Int) throws -> String {
        try data.withParserSpan { span in
            guard let range = ranges.strings else {
                throw ParsingError()
            }
            try span.seek(toRange: range)
            try span.seek(toRelativeOffset: offset)
            return try String(parsingNulTerminated: &span)
        }
    }
    
    static func parseCompressedUnsignedInteger(span: inout ParserSpan) throws -> UInt32 {
        let b1 = try UInt32(parsingLittleEndian: &span, byteCount: 1)
        
        if b1 >> 7 == 0b0 {
            // Bit 7 clear, value held in bits 6 through 0
            return b1
            
        } else if b1 >> 6 == 0b10 {
            // Bit 7 set, bit 6 clear, value held in bits 5 through 0 and the next byte
            let b2 = try UInt32(parsingLittleEndian: &span, byteCount: 1)
            return ((b1 & 0b0011_1111) << 8) | b2
            
        } else if b1 >> 5 == 0b110 {
            // Bit 7 and 6 set, bit 5 clear, value held in bits 4 through 0 and the next 3 bytes
            let b2 = try UInt32(parsingLittleEndian: &span, byteCount: 1)
            let b3 = try UInt32(parsingLittleEndian: &span, byteCount: 1)
            let b4 = try UInt32(parsingLittleEndian: &span, byteCount: 1)
            
            return ((b1 & 0b0001_1111) << 24)
                | (b2 << 16)
                | (b3 << 8)
                | b4
            
        } else {
            throw ParsingError()
        }
    }
}
