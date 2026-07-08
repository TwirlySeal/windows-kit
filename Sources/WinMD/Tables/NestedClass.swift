import BinaryParsing

enum NestedClassError: Error {
    case missingNestedClass
    case missingEnclosingClass
}

struct NestedClass {
    private let file: MetadataFile
    
    private let nestedClassIndex: Index
    private let enclosingClassIndex: Index
    
    var nestedClass: TypeDef {
        get throws { try .init(in: file, at: nestedClassIndex) }
    }
    
    var enclosingClass: TypeDef {
        get throws { try .init(in: file, at: enclosingClassIndex) }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan) throws {
        self.file = file
        
        guard let nestedClassIndex = try Index(parsing: &span, size: file.indexSizes.typeDef) else {
            throw NestedClassError.missingNestedClass
        }
        self.nestedClassIndex = nestedClassIndex
        
        guard let enclosingClassIndex = try Index(parsing: &span, size: file.indexSizes.typeDef) else {
            throw NestedClassError.missingEnclosingClass
        }
        self.enclosingClassIndex = enclosingClassIndex
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .nestedClass, at: rowIndex) { span in
            try Self(in: file, parsing: &span)
        }
    }
}
