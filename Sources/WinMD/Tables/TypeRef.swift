import BinaryParsing

public struct TypeRef {
    private let file: MetadataFile
    private let rowIndex: Index
    
    // Not used
    private let resolutionScopeIndex: CodedIndex<ResolutionScope.Tag>?
    
    private let typeNameIndex: HeapIndex
    private let typeNamespaceIndex: HeapIndex
    
    var name: String {
        get throws { try file.string(at: typeNameIndex) }
    }
    
    var namespace: String {
        get throws { try file.string(at: typeNamespaceIndex) }
    }
    
    var customAttributes: [CustomAttribute] {
        get throws {
            try CustomAttribute.rowRange(
                tag: .typeRef,
                forParent: self.rowIndex,
                in: file
            ).map { index in
                try CustomAttribute(in: file, at: index)
            }
        }
    }
    
    private init(in file: MetadataFile, parsing span: inout ParserSpan, _ rowIndex: Index) throws {
        self.file = file
        self.rowIndex = rowIndex
        
        self.resolutionScopeIndex = try CodedIndex<ResolutionScope.Tag>(
            parsing: &span,
            size: file.codedIndexSizes.resolutionScope
        )
        self.typeNameIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
        self.typeNamespaceIndex = try HeapIndex(parsing: &span, size: file.heapSizes.stringSize)
    }
    
    init(in file: MetadataFile, at rowIndex: Index) throws {
        self = try file.withRowSpan(in: .typeRef, at: rowIndex) { span in
            try Self(in: file, parsing: &span, rowIndex)
        }
    }
}
