import BinaryParsing
import Algorithms
import Foundation

extension Array {
	init<E: Error>(count: Int, element: () throws(E) -> Element) throws(E) {
		self.init()
		self.reserveCapacity(count)
		for _ in 1...count {
			self.append(try element())
		}
	}
}

struct ParsingError: Error {}

typealias TableSlots<Element> = InlineArray<64, Element>

struct MetadataInfo {
	let tables: TableSlots<ParserRange?>
	let rowCounts: TableSlots<UInt32>
	let strides: TableSlots<Int>

	let heapSizes: HeapSizes?
	let indexSizes: IndexSizes?
	let codedIndexSizes: CodedIndexSizes?
	private let sorted: UInt64

	let strings: ParserRange?
	let userStrings: ParserRange?
	let guid: ParserRange?
	let blob: ParserRange?

	func isSorted(table: TableKind) -> Bool {
		sorted & (1 << table.rawValue) != 0
	}

	init(parsing input: inout ParserSpan) throws {
		let streams = try Self.parseStart(&input)

		guard let metadataStream = streams["#~"] else {
			throw ParsingError()
		}
		try input.seek(toAbsoluteOffset: metadataStream.offset)

		// skip Reserved, MajorVersion, MinorVersion
		try input.seek(toRelativeOffset: 4+1+1)
		let heapSizes = HeapSizes(rawValue: try UInt8(parsingLittleEndian: &input, byteCount: 1))
		self.heapSizes = heapSizes

		try input.seek(toRelativeOffset: 1) // skip Reserved
		let valid = try UInt64(parsingLittleEndian: &input)
		self.sorted = try UInt64(parsingLittleEndian: &input)

		// Filter valid tables and parse Rows
		var rowCounts = TableSlots<UInt32>(repeating: 0)
		for i in rowCounts.indices {
			guard valid & (1 << i) != 0 else {
				continue
			}

			rowCounts[i] = try UInt32(parsingLittleEndian: &input)
		}
		self.rowCounts = rowCounts

		let indexSizes = IndexSizes(rowCounts)
		let codedIndexSizes = CodedIndexSizes(rowCounts)
		self.indexSizes = indexSizes
		self.codedIndexSizes = codedIndexSizes

		// Get table ranges
		var strides = TableSlots<Int>(repeating: 0)
		var tables = TableSlots<ParserRange?>(repeating: nil)
		for i in rowCounts.indices {
			let rowCount = rowCounts[i]
			guard rowCount > 0 else { continue }

			guard let kind = TableKind(rawValue: i) else {
				throw ParsingError()
			}

			let stride = kind.stride(heapSizes, indexSizes, codedIndexSizes)
			strides[i] = stride

			tables[i] = try input.sliceRange(
				objectStride: stride,
				objectCount: rowCount
			)
		}
		self.strides = strides
		self.tables = tables

		// bruh
		self.strings = nil
		self.blob = nil
		self.guid = nil
		self.userStrings = nil

		// for stream in streams {
		// 	try input.seek(toAbsoluteOffset: stream.offset)

		// 	switch stream.name {
		// 		case "#~":
		// 			// skip Reserved, MajorVersion, MinorVersion
		// 			try input.seek(toRelativeOffset: 4+1+1)
		// 			let heapSizes = HeapSizes(rawValue: try UInt8(parsingLittleEndian: &input, byteCount: 1))
		// 			self.heapSizes = heapSizes

		// 			try input.seek(toRelativeOffset: 1) // skip Reserved
		// 			let valid = try UInt64(parsingLittleEndian: &input)
		// 			sorted = try UInt64(parsingLittleEndian: &input)

		// 			// Filter valid tables and parse Rows
		// 			for i in rowCounts.indices {
		// 				guard valid & (1 << i) != 0 else {
		// 					continue
		// 				}

		// 				rowCounts[i] = try UInt32(parsingLittleEndian: &input)
		// 			}

		// 			let indexSizes = IndexSizes(rowCounts)
		// 			let codedIndexSizes = CodedIndexSizes(rowCounts)
		// 			self.indexSizes = indexSizes
		// 			self.codedIndexSizes = codedIndexSizes

		// 			// Get table ranges
		// 			for i in rowCounts.indices {
		// 				let rowCount = rowCounts[i]
		// 				guard rowCount > 0 else { continue }

		// 				guard let kind = TableKind(rawValue: i) else {
		// 					throw ParsingError()
		// 				}

		// 				let stride = kind.stride(heapSizes, indexSizes, codedIndexSizes)
		// 				strides[i] = stride

		// 				tables[i] = try input.sliceRange(
		// 					objectStride: stride,
		// 					objectCount: rowCount
		// 				)
		// 			}

		// 		case "#Strings":
		// 			strings = try input.sliceRange(byteCount: stream.size)

		// 		case "#US": // User Strings
		// 			userStrings = try input.sliceRange(byteCount: stream.size)

		// 		case "#GUID":
		// 			guid = try input.sliceRange(byteCount: stream.size)

		// 		case "#Blob":
		// 			blob = try input.sliceRange(byteCount: stream.size)
		// 		default:
		// 			throw ParsingError()
		// 	}
		// }
	}

	/// WinMD files are .NET assemblies, which are stored in a subset of the Microsoft Portable Executable format
	/// They only contain metadata and no executable code
	///
	/// Relevant ECMA-335 sections:
	/// - II.25 File format extensions to PE
	///
	/// Also useful: https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
	private static func parseStart(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
		try #magicNumber("MZ", parsing: &input) // MS-DOS header

		try input.seek(toAbsoluteOffset: 0x3c)
		let peSignatureOffset = try UInt32(parsingLittleEndian: &input)
		try input.seek(toAbsoluteOffset: peSignatureOffset)
	
		let peSignature = try UInt32(parsingLittleEndian: &input)
		guard peSignature == 0x00004550 else { // PE\0\0
			throw ParsingError()
		}

		// PE File Header/COFF File Header
		try input.seek(toRelativeOffset: 2) // skip Machine
		let numberOfSections = try UInt16(parsingLittleEndian: &input)

		// TimeDateStamp, PointerToSymbolTable, NumberOfSymbols, SizeOfOptionalHeader, Characteristics
		let restOfPEFields = 4+4+4+2+2

		// PE Optional Header -> Data Directories -> CLI Header field
		let CLIHeaderFieldOffset = 208
		try input.seek(toRelativeOffset: restOfPEFields + CLIHeaderFieldOffset)

		let CLI_RVA = try UInt32(parsingLittleEndian: &input)
		// skip CLI Size and Reserved
		try input.seek(toRelativeOffset: 4 + 8)

		// Section Table
		let sectionTable = try SectionTable(parsing: &input, numberOfSections)

		// CLI Header, skipping Cb, MajorRuntimeVersion, MinorRuntimeVersion
		try input.seek(
			toAbsoluteOffset: sectionTable.fileOffset(rva: CLI_RVA)+4+2+2
		)
		let metadataRVA = try UInt32(parsingLittleEndian: &input)

		// Metadata Root
		try input.seek(toAbsoluteOffset: sectionTable.fileOffset(rva: metadataRVA))
		return try parseMetadata(&input)
	}

	private struct SectionTable {
		struct Section {
			let virtualAddress: UInt32
			let virtualSize: UInt32
			let pointerToRawData: UInt32

			init(parsing input: inout ParserSpan) throws {
				try input.seek(toRelativeOffset: 8) // skip Name
				virtualSize = try UInt32(parsingLittleEndian: &input)
				virtualAddress = try UInt32(parsingLittleEndian: &input)
				try input.seek(toRelativeOffset: 4) // skip SizeOfRawData
				pointerToRawData = try UInt32(parsingLittleEndian: &input)

				// skip PointerToRelocations, PointerToLinenumbers, NumberOfRelocations, NumberOfLinenumbers, Characteristics
				try input.seek(toRelativeOffset: 4+4+2+2+4)
			}
		}

		var sections: [Section]

		init(parsing input: inout ParserSpan, _ numberOfSections: UInt16) throws {
			sections = try .init(count: Int(numberOfSections)) {
				try Section(parsing: &input)
			}
		}

		func fileOffset(rva: UInt32) throws -> UInt32 {
			// Find the first section where the RVA is less than the end of the section (binary search)
			let index = sections.partitioningIndex {
				rva < $0.virtualAddress + $0.virtualSize
			}

			// `partitioningIndex()` returns the count if the item is not found
			guard index < sections.count else {
				throw ParsingError()
			}

			let section = sections[index]

			guard section.virtualAddress <= rva else {
				throw ParsingError()
			}

			return section.pointerToRawData + (rva - section.virtualAddress)
		}
	}

	/// See ECMA-335 - II.24 Metadata physical layout
	private static func parseMetadata(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
		let startOfMetadataRoot = input.startPosition

		let metadataSignature = try UInt32(parsingLittleEndian: &input)
		guard metadataSignature == 0x424A5342 else {
			throw ParsingError()
		}
		// skip MajorVersion, MinorVersion, Reserved
		try input.seek(toRelativeOffset: 2+2+4)
		let versionLength = try UInt32(parsingLittleEndian: &input)
		// skip Version string and Flags
		try input.seek(toRelativeOffset: versionLength + 2)
		let numberOfStreams = try UInt16(parsingLittleEndian: &input)

		// Stream headers
		var streams = [String: StreamInfo]()
		streams.reserveCapacity(Int(numberOfStreams))
		for _ in 0..<numberOfStreams {
			let stream = try Stream(parsing: &input, startOfMetadataRoot)

			guard streams[stream.name] == nil else {
				throw ParsingError()
			}

			streams[stream.name] = StreamInfo(
				offset: stream.offset,
				size: stream.size
			)
		}

		return streams
	}

	private struct StreamInfo {
		let offset: Int
		let size: UInt32
	}

	private struct Stream {
		let offset: Int
		let size: UInt32
		let name: String

		init(parsing input: inout ParserSpan, _ startOfMetadataRoot: Int) throws {
			self.offset = startOfMetadataRoot + (try Int(parsingLittleEndian: &input, byteCount: 4))
			self.size = try UInt32(parsingLittleEndian: &input) // Size

			// Name is:
			// - A null-terminated, variable length ASCII string
			// - Padded to the next 4-byte boundary with null characters
			// - Limited to 32 characters
			let (name, paddedLength) = try input.withUnsafeBytes { buffer in
				let limit = 32
				let searchRange = buffer.prefix(limit)

				guard let nameLength = searchRange.firstIndex(of: 0) else {
					throw ParsingError()
				}

				return (
					// String does not include null terminator
					String(bytes: searchRange.prefix(nameLength), encoding: .ascii),

					// Add one to include null terminator, then round to next multiple of 4
					(nameLength + 1 + 3) & ~3
				)
			}
			try input.seek(toRelativeOffset: paddedLength)
			guard let name else {
				throw ParsingError()
			}
			self.name = name
		}
	}
}

struct HeapSizes: OptionSet {
	let rawValue: UInt8

	static let wideStrings = HeapSizes(rawValue: 1 << 0)
	static let wideGuids = HeapSizes(rawValue: 1 << 1)
	static let wideBlobs = HeapSizes(rawValue: 1 << 2)

	private func size(for flag: HeapSizes) -> Int {
		return contains(flag) ? 4 : 2
	}
	
	var stringSize: Int {
		size(for: .wideStrings)
	}

	var guidSize: Int {
		size(for: .wideGuids)
	}

	var blobSize: Int {
		size(for: .wideBlobs)
	}
}
