import BinaryParsing

enum NestedClassError: Error {
    case missingNestedClass
    case missingEnclosingClass
}

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
    
    private init(metadata: MetadataDB, span: inout ParserSpan) throws {
        self.metadata = metadata
        
        guard let nestedClassIndex = try Index(parsing: &span, size: metadata.indexSizes.typeDef) else {
            throw NestedClassError.missingNestedClass
        }
        self.nestedClassIndex = nestedClassIndex
        
        guard let enclosingClassIndex = try Index(parsing: &span, size: metadata.indexSizes.typeDef) else {
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
