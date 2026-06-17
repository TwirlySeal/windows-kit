import BinaryParsing
import Foundation

/// Search for End of Central Directory Signature (0x06054b50) from end
func findEOCD(span: borrowing Span<UInt8>) -> Int? {
	// The EOCD record is at least 22 bytes long (including the 4-byte signature)
	let startIndex = span.count - 22
	guard startIndex >= 0 else { return nil }

	// The ZIP file comment length field is 2 bytes
	// so the max length is 65,535 bytes
	// and the signature cannot exist further back than this
	let lowerBound = max(0, startIndex - Int(UInt16.max))

	for i in stride(from: startIndex, through: lowerBound, by: -1) {
		// Reversed because of little endian
		if (
			span[i] == 0x50 &&
			span[i + 1] == 0x4b &&
			span[i + 2] == 0x05 &&
			span[i + 3] == 0x06
		) {
			return i
		}
	}
	return nil
}

enum ZipError: Error {
	case noCentralDirectory
	case invalidCentralHeaderSignature
	case unsupportedMinVersion
	case unsupportedCompressionMethod
	case encrypted
    case invalidLocalHeaderSignature
}

public func parseZip(byteSpan: borrowing Span<UInt8>) throws -> [CentralDirectoryEntry] {
	guard let eocdOffset = findEOCD(span: byteSpan) else {
		throw ZipError.noCentralDirectory
	}
	var span = ParserSpan(byteSpan.bytes)
	try span.seek(toAbsoluteOffset: eocdOffset)

	// Skip:
	// - signature,
	// - disk number,
	// - central directory start disk number
	// - entries on this disk
	try span.seek(toRelativeOffset: 4 + 2 + 2 + 2)
	let numberOfEntries = try UInt16(parsingLittleEndian: &span)
	let centralDirectorySize = try UInt32(parsingLittleEndian: &span)
	let centralDirectoryOffset = try UInt32(parsingLittleEndian: &span)

	try span.seek(toAbsoluteOffset: centralDirectoryOffset)
	var centralDirectorySpan = try span.sliceSpan(byteCount: centralDirectorySize)

    let zipEntries = try Array(count: Int(numberOfEntries)) {
        try CentralDirectoryEntry(parsing: &centralDirectorySpan)
    }
    return zipEntries
}

public enum CompressionMethod: UInt16 {
	case stored = 0
	case deflate = 8
}

struct GeneralFlags: OptionSet {
	let rawValue: UInt16

	static let encrypted = Self(rawValue: 1)
}

public struct CentralDirectoryEntry {
	public let compressionMethod: CompressionMethod
	let crc32Checksum: UInt32
	let compressedSize: UInt32
	let uncompressedSize: UInt32
	public let fileName: String
    let localHeaderOffset: UInt32

	init(parsing span: inout ParserSpan) throws {
		guard try UInt32(parsingLittleEndian: &span) == 0x02014b50 else {
			throw ZipError.invalidCentralHeaderSignature
		}
		try span.seek(toRelativeOffset: 2) // skip verson made by

		// Only up to version 2.0 (Deflate) is supported
		guard try UInt16(parsingLittleEndian: &span) <= 20 else {
			throw ZipError.unsupportedMinVersion
		}
		let generalFlags = GeneralFlags(rawValue: try UInt16(parsingLittleEndian: &span))
		// Encryption is not supported
		guard !generalFlags.contains(.encrypted) else {
			throw ZipError.encrypted
		}

		guard let compressionMethod = CompressionMethod(rawValue: try UInt16(parsingLittleEndian: &span)) else {
			throw ZipError.unsupportedCompressionMethod
		}
		self.compressionMethod = compressionMethod

		try span.seek(toRelativeOffset: 2 + 2) // skip last mod file time and date

		self.crc32Checksum = try UInt32(parsingLittleEndian: &span)
		self.compressedSize = try UInt32(parsingLittleEndian: &span)
		self.uncompressedSize = try UInt32(parsingLittleEndian: &span)

		let fileNameLength = try UInt16(parsingLittleEndian: &span)
		let extraFieldLength = try UInt16(parsingLittleEndian: &span)
		let fileCommentLength = try UInt16(parsingLittleEndian: &span)

		// skip disk number start, internal and external file attributes
		try span.seek(toRelativeOffset: 2 + 2 + 4)

        self.localHeaderOffset = try UInt32(parsingLittleEndian: &span)

		// ZIP 2.0 only supports IBM Code Page 437 but:
		// - This is a superset of ASCII
		// - NuGet WinMD packages only use ASCII characters
		// - UTF-8 is a superset of ASCII
		self.fileName = try String(parsingUTF8: &span, count: Int(fileNameLength))
		try span.seek(toRelativeOffset: extraFieldLength + fileCommentLength) // skip
	}
}

public struct ZipEntry: ~Copyable, ~Escapable {
    private let span: Span<UInt8>
    private let centralDirectoryEntry: CentralDirectoryEntry
    
    public var fileName: String {
        centralDirectoryEntry.fileName
    }
    
    @_lifetime(copy span)
    public init(span: Span<UInt8>, centralDirectoryEntry: CentralDirectoryEntry) throws {
        self.centralDirectoryEntry = centralDirectoryEntry
        
        var parser = ParserSpan(span.bytes)
        try parser.seek(toAbsoluteOffset: centralDirectoryEntry.localHeaderOffset)
        guard try UInt32(parsingLittleEndian: &parser) == 0x04034b50 else {
            throw ZipError.invalidLocalHeaderSignature
        }
        // Skip other fields
        try parser.seek(toRelativeOffset: 22)
        
        let fileNameLength = try UInt16(parsingLittleEndian: &parser)
        let extraFieldLength = try UInt16(parsingLittleEndian: &parser)
        
        try parser.seek(toRelativeOffset: fileNameLength + extraFieldLength)
        let start = parser.startPosition
        let end = start + Int(centralDirectoryEntry.compressedSize)
        self.span = span.extracting(start..<end)
    }
    
    public func extract() throws -> Data {
        return try parseDeflate(span: self.span, uncompressedSize: Int(centralDirectoryEntry.uncompressedSize))
    }
}
