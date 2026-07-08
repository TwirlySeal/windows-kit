import BinaryParsing

struct TypeSpec {
    private let file: MetadataFile
    private let rowIndex: Index
    
    private let signatureIndex: HeapIndex
    
    var type: Type {
        get throws { try .init(in: file, at: signatureIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.equalRange(
                in: file,
                tag: .typeSpec,
                index: self.rowIndex
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        self.signatureIndex = try HeapIndex(parsing: &span, size: file.heapSizes.blobSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .typeSpec, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
