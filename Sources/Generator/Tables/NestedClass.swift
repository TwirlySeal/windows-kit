import BinaryParsing

struct NestedClass {
    private let metadata: MetadataDB
    
    private let nestedClassIndex: Index
    private let enclosingClassIndex: Index
    
    var nestedClass: TypeDef {
        get throws { try .init(metadata: metadata, rowIndex: nestedClassIndex) }
    }
    
    var enclosingClass: TypeDef {
        get throws { try .init(metadata: metadata, rowIndex: enclosingClassIndex) }
    }
    
    enum NestedClassError: Error {
        case missingNestedClass
        case missingEnclosingClass
    }
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        let nestedClassValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.typeDef))
        guard let nestedClassIndex = Index(rawValue: nestedClassValue) else {
            throw NestedClassError.missingNestedClass
        }
        self.nestedClassIndex = nestedClassIndex
        
        let enclosingClassValue = try UInt32(parsingLittleEndian: &span, byteCount: Int(metadata.indexSizes.typeDef))
        guard let enclosingClassIndex = Index(rawValue: enclosingClassValue) else {
            throw NestedClassError.missingEnclosingClass
        }
        self.enclosingClassIndex = enclosingClassIndex
    }
    
    init(metadata: MetadataDB, rowIndex: Index) throws {
        self = try metadata.withRowSpan(in: .nestedClass, rowIndex: rowIndex) { span in
            try Self(metadata: metadata, span: &span)
        }
    }
}
