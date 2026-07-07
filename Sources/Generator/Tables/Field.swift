import BinaryParsing

enum FieldError: Error {
    case invalidFieldAttributes
}

struct Field {
    private let file: MetadataFile
    private let rowIndex: Index
    
    let flags: FieldAttributes
    private let nameIndex: HeapIndex
    private let signatureIndex: HeapIndex
    
    var name: String {
        get throws { try file.string(at: nameIndex) }
    }
    
    var signature: FieldSig {
        get throws { try .init(in: file, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .field,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
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
