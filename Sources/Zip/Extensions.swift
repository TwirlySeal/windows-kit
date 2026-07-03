import Foundation

extension Array {
    init<E: Error>(count: Int, element: () throws(E) -> Element) throws(E) {
        self.init()
        self.reserveCapacity(count)
        for _ in 0..<count {
            self.append(try element())
        }
    }
}

enum CopyError: Error {
    case insufficientSpace
}

extension Span<UInt8> {
    func copy(to output: inout OutputSpan<UInt8>) throws {
        try self.withUnsafeBufferPointer { sourceBuffer in
            guard sourceBuffer.count > 0 else { return }
            
            try output.withUnsafeMutableBufferPointer { outputBuffer, initializedCount in
                let availableSpace = outputBuffer.count - initializedCount
                guard availableSpace >= sourceBuffer.count else {
                    throw CopyError.insufficientSpace
                }
                
                guard let sourceAddress = sourceBuffer.baseAddress,
                      let destinationAddress = outputBuffer.baseAddress else {
                    return
                }
                
                let writeAddress = destinationAddress.advanced(by: initializedCount)
                writeAddress.initialize(from: sourceAddress, count: sourceBuffer.count)
                
                initializedCount += sourceBuffer.count
            }
        }
    }
}

extension Data {
    init<E: Error>(
        capacity: Int,
        initializingWith initializer: (_ span: inout OutputSpan<UInt8>) throws(E) -> Void
    ) throws {
        self = Data(count: capacity) // O(n) zero-initialization
        
        self.count = try withUnsafeMutableBytes { rawBuffer in
            let typedBuffer = rawBuffer.bindMemory(to: UInt8.self)
            var span = OutputSpan<UInt8>(buffer: typedBuffer, initializedCount: 0)
            try initializer(&span)
            return span.finalize(for: typedBuffer)
        }
    }
}

