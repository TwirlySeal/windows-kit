import BinaryParsing

enum FieldError: Error {
    case invalidFieldAttributes
}

public struct Field {
    private let file: MetadataFile
    private let rowIndex: Index
    
    public let flags: FieldAttributes
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    
    public var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    public var signature: FieldSig {
        get throws { try .init(in: file, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.rowRange(
                tag: .field,
                forParent: self.rowIndex,
                in: file
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    public var constant: Constant? {
        get throws {
            try Constant.rowRange(
                tag: .field,
                forParent: self.rowIndex,
                in: file
            ).first.map { index in
                try Constant(in: file, at: index)
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        guard let flags = FieldAttributes(rawValue: try UInt16(parsingLittleEndian: &span)) else {
            throw FieldError.invalidFieldAttributes
        }
        self.flags = flags
        self.nameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        self.signatureIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .field, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
