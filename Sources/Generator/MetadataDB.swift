import Foundation
import BinaryParsing
import Algorithms

extension Array {
    init<E: Error>(count: Int, element: () throws(E) -> Element) throws(E) {
        self.init()
        self.reserveCapacity(count)
        for _ in 1...count {
            self.append(try element())
        }
    }
}

enum MetadataError: Error {
    case missingMetadataStream
    case unknownTable
    case missingStringStream
    case invalidPESignature
    case invalidRVA
    case invalidMetadataSignature
    case duplicateStream(name: String)
    case missingNullTerminator
    case invalidStreamName
    case missingTable
    case indexOutOfBounds
    case invalidCompressedInteger
    case invalidCodedIndexTag
}

/// Manages the binary data of a metadata file and information needed to parse
/// table rows. Lightweight view structs representing table rows are parsed on
/// demand, and hold a reference to this class for indices into other tables.
/// This allows them to make the index private and provide computed properties
/// that parse the linked table row when it is accessed.
///
/// View structs go in the Tables folder
final class MetadataDB {
    private let data: Data
    
    // Metadata stream
    struct Table {
        let range: ParserRange
        let rowCount: UInt32
        let stride: Int
    }
    private let tables: [64 of Table?]

    // Info
    let heapSizes: HeapSizes
    let indexSizes: IndexSizes
    let codedIndexSizes: CodedIndexSizes
    private let sorted: UInt64

    // Heaps
    private let stringHeap: ParserRange
    private let userStringHeap: ParserRange?
    private let guidHeap: ParserRange?
    private let blobHeap: ParserRange?

    func isSorted(table: TableKind) -> Bool {
        sorted & (1 << table.rawValue) != 0
    }
    
    /// Calculates the row range in a linked table for a list column
    func listRowRange(
        rowIndex: Int,
        startListIndex: Int,
        currentTable: TableKind,
        linkedTable: TableKind,
        readNextPointer: (_ nextRowIndex: Int) throws -> Int
    ) throws -> Range<Int> {
        guard let currentTable = tables[currentTable.rawValue],
              let linkedTable = tables[linkedTable.rawValue] else {
            throw MetadataError.missingTable
        }
        
        let endIndexExclusive: Int = if rowIndex < currentTable.rowCount {
            // Defer to the caller to extract the pointer from the next row
            
            // While the caller could compute `rowIndex + 1` themselves, passing it
            // as a parameter to the closure means `MetadataDB` owns the logic of how
            // list columns work and the closure simply fetches the pointer at the provided
            // row index.
            try readNextPointer(rowIndex + 1)
        } else {
            // We are at the final row; span to the end of the linked table
            Int(linkedTable.rowCount) + 1
        }
        
        // If `startListIndex == endIndexExclusive`, the range is empty (Count: 0)
        return startListIndex..<endIndexExclusive
    }
    
    /// Parse one row of a table
    /// Tables are one-indexed, meaning `rowIndex: n` gives the nth row.
    /// This method will throw for `rowIndex: 0` as an index of 0 is reserved to mean null (no index)
    func withRowSpan<T>(in table: TableKind, rowIndex: Int, _ body: (inout ParserSpan) throws -> T) throws -> T {
        try data.withParserSpan { span in
            guard let table = tables[table.rawValue] else {
                throw MetadataError.missingTable
            }
            let zeroBasedIndex = rowIndex - 1
            guard zeroBasedIndex >= 0, zeroBasedIndex < table.rowCount else {
                throw MetadataError.indexOutOfBounds
            }
            try span.seek(toRange: table.range)
            
            let stride = table.stride
            try span.seek(toRelativeOffset: stride * rowIndex)
            
            var rowSpan = try span.sliceSpan(byteCount: stride)
            return try body(&rowSpan)
        }
    }
    
    /// Read from the string heap
    func string(at offset: Int) throws -> String {
        try data.withParserSpan { span in
            try span.seek(toRange: stringHeap)
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
            throw MetadataError.invalidCompressedInteger
        }
    }
    
    init(parsing data: Data) throws {
        self.data = data
        var span = ParserSpan(data.span.bytes)
        
        let streams = try Self.getStreams(&span)

        guard let metadataStream = streams["#~"] else {
            throw MetadataError.missingMetadataStream
        }
        try span.seek(toAbsoluteOffset: metadataStream.offset)

        // skip Reserved, MajorVersion, MinorVersion
        try span.seek(toRelativeOffset: 4+1+1)
        self.heapSizes = HeapSizes(rawValue: try UInt8(parsingLittleEndian: &span, byteCount: 1))

        try span.seek(toRelativeOffset: 1) // skip Reserved
        let valid = try UInt64(parsingLittleEndian: &span)
        self.sorted = try UInt64(parsingLittleEndian: &span)

        // Filter valid tables and parse Rows
        var rowCounts = [64 of UInt32](repeating: 0)
        for i in rowCounts.indices {
            guard valid & (1 << i) != 0 else {
                continue
            }

            rowCounts[i] = try UInt32(parsingLittleEndian: &span)
        }

        self.indexSizes = IndexSizes(rowCounts)
        self.codedIndexSizes = CodedIndexSizes(rowCounts)

        // Get table ranges
        var tables = [64 of Table?](repeating: nil)
        for i in rowCounts.indices {
            let rowCount = rowCounts[i]
            guard rowCount > 0 else { continue }

            guard let kind = TableKind(rawValue: i) else {
                throw MetadataError.unknownTable
            }

            let stride = kind.stride(heapSizes, indexSizes, codedIndexSizes)
            let range = try span.sliceRange(
                objectStride: stride,
                objectCount: rowCount
            )
            
            tables[i] = Table(
                range: range,
                rowCount: rowCount,
                stride: stride
            )
        }
        self.tables = tables

        // Heaps
        guard let stringStream = streams["#Strings"] else {
            throw MetadataError.missingStringStream
        }
        try span.seek(toAbsoluteOffset: stringStream.offset)
        self.stringHeap = try span.sliceRange(byteCount: stringStream.size)
        
        if let blobStream = streams["#Blob"] {
            try span.seek(toAbsoluteOffset: blobStream.offset)
            self.blobHeap = try span.sliceRange(byteCount: blobStream.size)
        } else {
            self.blobHeap = nil
        }
        
        if let guidStream = streams["#GUID"] {
            try span.seek(toAbsoluteOffset: guidStream.offset)
            self.guidHeap = try span.sliceRange(byteCount: guidStream.size)
        } else {
            self.guidHeap = nil
        }
        
        if let userStringsStream = streams["#US"] {
            try span.seek(toAbsoluteOffset: userStringsStream.offset)
            self.userStringHeap = try span.sliceRange(byteCount: userStringsStream.size)
        } else {
            self.userStringHeap = nil
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

    /// WinMD files are .NET assemblies, which are stored in a subset of the Microsoft Portable Executable format
    /// They only contain metadata and no executable code
    ///
    /// Relevant ECMA-335 sections:
    /// - II.25 File format extensions to PE
    ///
    /// Also useful: https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
    private static func getStreams(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
        try #magicNumber("MZ", parsing: &input) // MS-DOS header

        try input.seek(toAbsoluteOffset: 0x3c)
        let peSignatureOffset = try UInt32(parsingLittleEndian: &input)
        try input.seek(toAbsoluteOffset: peSignatureOffset)
    
        let peSignature = try UInt32(parsingLittleEndian: &input)
        guard peSignature == 0x00004550 else { // PE\0\0
            throw MetadataError.invalidPESignature
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

        let sections: [Section]

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
                throw MetadataError.invalidRVA
            }

            let section = sections[index]

            guard section.virtualAddress <= rva else {
                throw MetadataError.invalidRVA
            }

            return section.pointerToRawData + (rva - section.virtualAddress)
        }
    }

    /// See ECMA-335 - II.24 Metadata physical layout
    private static func parseMetadata(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
        let startOfMetadataRoot = input.startPosition

        let metadataSignature = try UInt32(parsingLittleEndian: &input)
        guard metadataSignature == 0x424A5342 else {
            throw MetadataError.invalidMetadataSignature
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
                throw MetadataError.duplicateStream(name: stream.name)
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
                    throw MetadataError.missingNullTerminator
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
                throw MetadataError.invalidStreamName
            }
            self.name = name
        }
    }
}
