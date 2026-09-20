import SystemPackage

extension MutableSpan where Element == UInt8 {
    /// Initializes this mutable span with the bytes from a source `Span`
    mutating func initialize(from source: Span<UInt8>) {
        precondition(source.count <= self.count, "Source is larger than bounds")

        self.withUnsafeMutableBufferPointer { destBuffer in
            source.withUnsafeBufferPointer { srcBuffer in
                guard let destBase = destBuffer.baseAddress,
                      let sourceBase = srcBuffer.baseAddress else { return }
                
                destBase.initialize(from: sourceBase, count: source.count)
            }
        }
    }
}

extension FileDescriptor {
    func write(_ span: borrowing RawSpan) throws -> Int {
        return try span.withUnsafeBytes { buffer in
            try self.write(UnsafeRawBufferPointer(buffer))
        }
    }
}

/// `close()` must be called to flush the buffer and close the file descriptor
/// Standard output streams should not be closed; use `flush()` instead
struct FileOutputStream: ~Copyable {
    let file: FileDescriptor
    /// 4 KB
    private var buffer = [4096 of UInt8](repeating: 0)
    private var count = 0
    
    init(at path: FilePath) throws {
        self.file = try FileDescriptor.open(path, .writeOnly)
    }
    
    private init(file: FileDescriptor) {
        self.file = file
    }
    
    static func standardOutput() -> Self {
        Self(file: .standardOutput)
    }
    
    mutating func flush() throws {
        guard count > 0 else { return }
        
        let activeSpan = buffer.span.extracting(0..<count)
        _ = try file.write(activeSpan.bytes)
        count = 0
    }
    
    consuming func close() throws {
        try flush()
        try file.close()
    }
    
    mutating func write(_ string: String) throws {
        let utf8Span = string.utf8Span
        let byteCount = utf8Span.count
        
        // Flush if buffer would overflow
        if count + byteCount > buffer.count {
            try flush()
        }
        
        // Bypass buffer for larger strings
        if byteCount > buffer.count {
            try utf8Span.withBytes { bytes in
                _ = try file.write(bytes)
            }
            return
        }
        
        var bufferSpan = buffer.mutableSpan
        var targetSpan = bufferSpan._mutatingExtracting(droppingFirst: count)
        targetSpan.initialize(from: utf8Span.span)
        count += byteCount
    }
}
