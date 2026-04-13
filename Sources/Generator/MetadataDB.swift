import Foundation
import BinaryParsing

/// Manages the binary data of a metadata file and information needed to parse
/// table rows. Lightweight view structs representing table rows are parsed on
/// demand, and hold a reference to this class for indices into other tables.
/// This allows them to make the index private and provide computed properties
/// that parse the linked table row when it is accessed.
///
/// View structs go in the Tables folder
class MetadataDB {
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
			return try String(parsingNulTerminated: &span)
		}
	}
    
//    static func decompressInteger(input: inout ParserSpan) throws -> UInt8 {
//        let oneByteMask: UInt = 0b1000_0000
//        let twoByteMask: UInt = 0b1100_0000
//        let fourByteMask: UInt = 0b1110_0000
//
//        let firstByte = try UInt8(parsingLittleEndian: &input, byteCount: 1)
//
//        return if firstByte & oneByteMask == 0 {
//            firstByte
//        } else if firstByte & twoByteMask == 0b1000_0000 {
//            ((nums[0] & 0b0011_1111) << 8) | nums[1]
//        } else if firstByte & fourByteMask == 0b1100_0000 {
//            ((nums[0] & 0b0001_1111) << 24) | (nums[1] << 16) | (nums[2] << 8) | nums[3]
//        } else {
//            throw ParsingError()
//        }
//    }
}
