import Foundation
import BinaryParsing
import Algorithms

enum MetadataFileError: Error {
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
    case missingBlobHeap
}

struct HeapIndex {
    let rawValue: UInt32
    
    init(parsing span: inout ParserSpan, size: Int) throws {
        self.rawValue = try .init(parsingLittleEndian: &span, byteCount: size)
    }
}

/// Manages the binary data of a metadata file and information needed to parse
/// its contents. Data is parsed into lightweight view structs that hold a
/// reference to this class to lazily parse linked data. These structs keep
/// indices and the file reference private, and provide throwing computed
/// properties that parse linked data when accessed.
///
/// Windows Metadata is like a graph of data linked via indices, so representing
/// it using classes would create reference cycle challenges and require parsing
/// all the data upfront which is inefficient. Parsing a view struct is cheap
/// because none of its linked data is resolved until it is needed.
///
/// This is a class because its large size would make it expensive to copy and it
/// is frequently passed around
public final class MetadataFile {
    private let data: Data
    
    // Metadata stream
    struct Table {
        let range: ParserRange
        let rowCount: UInt32
        let stride: Int
    }
    /// Indexed by `TableID` raw values, matching bit sets such as Valid and Sorted
    ///
    /// The format stores table information like a structure of arrays, but it
    /// has been transposed to an array of structures to align with the access
    /// pattern of using multiple details about the table at once (ergonomics
    /// and cache density)
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

    func isSorted(table: TableID) -> Bool {
        sorted & (1 << table.rawValue) != 0
    }
    
    /// Get a range over all the row indices in a table
    func tableRange(in table: TableID) throws -> Range<Index> {
        let firstIndex = Index(rawValue: 1)!
        
        guard let table = tables[table.rawValue] else {
            return firstIndex..<firstIndex
        }
        let lastIndexExclusive = Index(rawValue: table.rowCount + 1)!
        return firstIndex..<lastIndexExclusive
    }
    
    /// Provides temporary access to a span over the bytes in a table row. The
    /// size of the span is equal to the stride of the table for safety.
    ///
    /// Tables are one-indexed, meaning an index of `n` gives the nth row. An
    /// index of 0 is reserved to mean null (no index)
    func withRowSpan<T>(in tableID: TableID, at rowIndex: Index, _ body: (inout ParserSpan) throws -> T) throws -> T {
        try data.withParserSpan { span in
            guard let table = tables[tableID.rawValue] else {
                throw MetadataFileError.missingTable
            }
            let zeroBasedIndex = Int(rowIndex.rawValue) - 1
            guard zeroBasedIndex >= 0, zeroBasedIndex < table.rowCount else {
                throw MetadataFileError.indexOutOfBounds
            }
            try span.seek(toRange: table.range)
            
            let stride = table.stride
            try span.seek(toRelativeOffset: stride * zeroBasedIndex)
            
            var rowSpan = try span.sliceSpan(byteCount: stride)
            return try body(&rowSpan)
        }
    }
    
    /// Calculates the row range in a linked table for a list column
    func listRowRange(
        rowIndex: Index,
        startListIndex: Index,
        currentTable: TableID,
        linkedTable: TableID,
        readPointer: (_ rowIndex: Index) throws -> Index?
    ) throws -> Range<Index> {
        guard let currentTable = tables[currentTable.rawValue],
              let linkedTable = tables[linkedTable.rawValue] else {
            throw MetadataFileError.missingTable
        }
        
        // Scan forward to find next non-null boundary
        var nextListIndex: Index? = nil
        if rowIndex.rawValue < currentTable.rowCount {
            let nextRowIndex = rowIndex.advanced(by: 1)
            let endRowIndex = Index(rawValue: currentTable.rowCount)!
            
            for index in nextRowIndex...endRowIndex {
                if let nextPointer = try readPointer(index) {
                    nextListIndex = nextPointer
                    break
                }
            }
        }
        
        // If we reached the final row and found no non-null pointers,
        // the run spans to the end of the linked table
        let endIndexExclusive = nextListIndex ?? Index(rawValue: linkedTable.rowCount + 1)!
        
        // If `startListIndex == endIndexExclusive`, the range is empty (Count: 0)
        return startListIndex..<endIndexExclusive
    }
    
    /// Finds the contiguous range of rows that match a target value
    /// Used for reverse lookups of rows in other tables that link to a given row
    func equalRange(in tableID: TableID, _ compare: (_ rowIndex: Index) throws -> Ordering) throws -> Range<Index> {
        guard let table = tables[tableID.rawValue] else {
            throw MetadataFileError.missingTable
        }
        
        // Binary search
        var first = 0
        var count = Int(table.rowCount)
        
        while count > 0 {
            let count2 = count / 2
            let middle = first + count2
            
            // Convert 0-based math to 1-based Index
            let rowIndex = Index(rawValue: .init(middle + 1))!
            
            let ordering = try compare(rowIndex)
            
            switch ordering {
            case .lessThan:
                first = middle + 1
                count -= (count2 + 1)
                
            case .greaterThan:
                count = count2
                
            case .equal:
                // We found a match. Now we find the absolute first and last occurrences.
                let firstMatch = try lowerBound(in: tableID, first: first, last: middle, compare)
                
                // 'first + count' represents the upper bound of the current search space.
                let lastMatch = try upperBound(in: tableID, first: middle + 1, last: first + count, compare)
                
                let startIndex = Index(rawValue: .init(firstMatch + 1))!
                let exclusiveEndIndex = Index(rawValue: .init(lastMatch + 1))!
                
                return startIndex..<exclusiveEndIndex
            }
        }
        
        // If not found, return an empty range at the insertion point
        let notFoundIndex = Index(rawValue: .init(first + 1))!
        return notFoundIndex..<notFoundIndex
    }
    
    /// Finds the first element in the range [first, last) that is not strictly less than the target
    private func lowerBound(
        in tableID: TableID,
        first: Int,
        last: Int,
        _ compare: (_ rowIndex: Index) throws -> Ordering
    ) throws -> Int {
        // Binary search
        var first = first
        var count = last - first
        
        while count > 0 {
            let count2 = count / 2
            let middle = first + count2
            
            let rowIndex = Index(rawValue: .init(middle + 1))!
            
            let ordering = try compare(rowIndex)
            
            if ordering == .lessThan {
                first = middle + 1
                count -= (count2 + 1)
            } else {
                count = count2
            }
        }
        return first
    }
    
    /// Finds the first element in the range [first, last) that is strictly greater than the target
    private func upperBound(
        in tableID: TableID,
        first: Int,
        last: Int,
        _ compare: (_ rowIndex: Index) throws -> Ordering
    ) throws -> Int {
        // Binary search
        var first = first
        var count = last - first
        
        while count > 0 {
            let count2 = count / 2
            let middle = first + count2
            
            let rowIndex = Index(rawValue: .init(middle + 1))!
            
            let ordering = try compare(rowIndex)
            
            if ordering == .greaterThan {
                count = count2
                
            } else {
                first = middle + 1
                count -= (count2 + 1)
            }
        }
        return first
    }
    
    /// Read from the string heap
    func string(at offset: HeapIndex) throws -> String {
        try data.withParserSpan { span in
            try span.seek(toRange: stringHeap)
            try span.seek(toRelativeOffset: offset.rawValue)
            return try String(parsingNulTerminated: &span)
        }
    }
    
    // Provides temporary access to a span over the bytes in a blob. Reads the compressed size prefix
    // so the span ends at the end of the blob for safety.
    func withBlobSpan<T>(at offset: HeapIndex, _ body: (inout ParserSpan) throws -> T) throws -> T {
        try data.withParserSpan { span in
            guard let blobHeap else {
                throw MetadataFileError.missingBlobHeap
            }
            try span.seek(toRange: blobHeap)
            try span.seek(toRelativeOffset: offset.rawValue)
            
            let length = try Self.parseCompressedUnsignedInteger(from: &span)

            var blobSpan = try span.sliceSpan(byteCount: length)
            return try body(&blobSpan)
        }
    }
    
    /// Used in blobs and signatures
    /// Max value: 0x1FFFFFFF
    static func parseCompressedUnsignedInteger(from span: inout ParserSpan) throws -> UInt32 {
        // Compressed integers are stored in big endian
        //
        // I'm not sure if big endian parsing involves byte-order swapping for
        // single-byte reads on little endian systems, but I used little endian
        // to avoid this overhead just in case it does
        let firstByte = try UInt32(parsingLittleEndian: &span, byteCount: 1)
        
        if firstByte >> 7 == 0b0 {
            // Bit 7 clear, value held in bits 6 through 0
            return firstByte
            
        } else if firstByte >> 6 == 0b10 {
            // Bit 7 set, bit 6 clear, value held in bits 5 through 0 and the next byte
            let secondByte = try UInt32(parsingLittleEndian: &span, byteCount: 1)
            return ((firstByte & 0b0011_1111) << 8) | secondByte
            
        } else if firstByte >> 5 == 0b110 {
            // Bit 7 and 6 set, bit 5 clear, value held in bits 4 through 0 and the next 3 bytes
            let remainingBytes = try UInt32(parsingBigEndian: &span, byteCount: 3)
            
            return ((firstByte & 0b0001_1111) << 24) | remainingBytes
            
        } else {
            throw MetadataFileError.invalidCompressedInteger
        }
    }
    
    /// Parse a length-prefixed UTF-8 string
    static func serString(parsing span: inout ParserSpan) throws -> String {
        // Null strings (with PackedLen = 0xFF) do not occur in Windows Metadata
        let packedLen = try Self.parseCompressedUnsignedInteger(from: &span)
        
        return try String(parsingUTF8: &span, count: Int(packedLen))
    }
    
    public init(parsing data: Data) throws {
        self.data = data
        var span = ParserSpan(data.span.bytes)
        
        let streams = try Self.getStreams(&span)

        guard let metadataStream = streams["#~"] else {
            throw MetadataFileError.missingMetadataStream
        }
        try span.seek(toAbsoluteOffset: metadataStream.offset)

        // skip Reserved, MajorVersion, MinorVersion
        try span.seek(toRelativeOffset: 4+1+1)
        self.heapSizes = HeapSizes(rawValue: try UInt8(parsing: &span))

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

            guard let kind = TableID(rawValue: i) else {
                throw MetadataFileError.unknownTable
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
            throw MetadataFileError.missingStringStream
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
    
    /// The sizes of indices into each heap (the number of bytes that should be
    /// read to parse a `HeapIndex`) depend on these bit flags
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

    /// WinMD files are .NET assemblies, which are stored in a subset of the
    /// Microsoft Portable Executable format. They only contain metadata and no
    /// executable code.
    ///
    /// We need to follow this format until we reach the metadata root where the
    /// Windows Metadata is actually stored.
    ///
    /// ### Resources:
    /// - ECMA-335 - §II.25 File format extensions to PE
    /// - https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
    private static func getStreams(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
        try #magicNumber("MZ", parsing: &input) // MS-DOS header

        try input.seek(toAbsoluteOffset: 0x3c)
        let peSignatureOffset = try UInt32(parsingLittleEndian: &input)
        try input.seek(toAbsoluteOffset: peSignatureOffset)
    
        let peSignature = try UInt32(parsingLittleEndian: &input)
        guard peSignature == 0x00004550 else { // PE\0\0
            throw MetadataFileError.invalidPESignature
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

    /// Represents the PE Section Table, which serves as a map to translate
    /// Relative Virtual Addresses (RVAs) into physical file offsets.
    ///
    /// - **File Offset:** The literal, byte-0-indexed position of data when the
    /// binary sits on disk.
    /// - **RVA:** When the Windows Loader maps a PE file from disk into RAM, it
    /// pads the sections (like `.text` for code or `.data` for variables) with
    /// zeros so that each section starts precisely on a memory page boundary.
    /// An RVA represents the position of data after this padding has been
    /// added.
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

        /// Find the file offset that corresponds to a given RVA
        func fileOffset(rva: UInt32) throws -> UInt32 {
            // Find the first section where the RVA is less than the end of the section (binary search)
            let index = sections.partitioningIndex { section in
                rva < section.virtualAddress + section.virtualSize
            }

            // `partitioningIndex()` returns the count if the item is not found
            guard index < sections.count else {
                throw MetadataFileError.invalidRVA
            }

            let section = sections[index]

            guard section.virtualAddress <= rva else {
                throw MetadataFileError.invalidRVA
            }

            return section.pointerToRawData + (rva - section.virtualAddress)
        }
    }

    /// See ECMA-335 - §II.24 Metadata physical layout
    private static func parseMetadata(_ input: inout ParserSpan) throws -> [String: StreamInfo] {
        let startOfMetadataRoot = input.startPosition

        let metadataSignature = try UInt32(parsingLittleEndian: &input)
        guard metadataSignature == 0x424A5342 else {
            throw MetadataFileError.invalidMetadataSignature
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
                throw MetadataFileError.duplicateStream(name: stream.name)
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
                    throw MetadataFileError.missingNullTerminator
                }

                return (
                    // String does not include null terminator
                    name: String(bytes: searchRange.prefix(nameLength), encoding: .ascii),

                    // Add one to include null terminator, then round to next multiple of 4
                    paddedLength: (nameLength + 1 + 3) & ~3
                )
            }
            try input.seek(toRelativeOffset: paddedLength)
            guard let name else {
                throw MetadataFileError.invalidStreamName
            }
            self.name = name
        }
    }
}
