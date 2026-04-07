import Foundation
import SystemPackage
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
}
