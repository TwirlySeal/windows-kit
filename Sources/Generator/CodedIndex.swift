import BinaryParsing

/// A coded index is an index into one of multiple possible tables
///
/// See ECMA-335 II.24.2.6, page 274
protocol CodedIndexTag: RawRepresentable where RawValue == Index.RawValue {
	/// The number of bits used to encode the tag.
	static var bits: Int { get }

	// The tables that the index may point into.
	static var tables: [TableID] { get }
}

struct CodedIndex<Tag: CodedIndexTag> {
    typealias RawValue = Tag.RawValue
    
    let tag: Tag
    let index: Index
    
    var rawValue: RawValue {
        (index.rawValue << Tag.bits) | tag.rawValue
    }
    
    init(tag: Tag, index: Index) {
        self.tag = tag
        self.index = index
    }
    
    init?(rawValue: RawValue) throws {
        let mask: RawValue = (1 << Tag.bits) - 1
        let tagBits = rawValue & mask
        guard let tag = Tag.init(rawValue: tagBits) else {
            throw MetadataFileError.invalidCodedIndexTag
        }
        
        guard let index = Index(rawValue: rawValue >> Tag.bits) else {
            return nil
        }
        
        self.tag = tag
        self.index = index
    }
    
    init?(parsing span: inout ParserSpan, size: UInt8) throws {
        try self.init(rawValue: try .init(parsingLittleEndian: &span, byteCount: Int(size)))
    }
}

extension CodedIndex: Equatable {
    static func == (lhs: CodedIndex<Tag>, rhs: CodedIndex<Tag>) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension CodedIndex: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct CodedIndexSizes {
    let hasConstant: UInt8
    let hasCustomAttribute: UInt8
    let customAttributeType: UInt8
    let hasDeclSecurity: UInt8
    let typeDefOrRef: UInt8
    let implementation: UInt8
    let hasFieldMarshal: UInt8
    let typeOrMethodDef: UInt8
    let memberForwarded: UInt8
    let memberRefParent: UInt8
    let methodDefOrRef: UInt8
    let hasSemantics: UInt8
    let resolutionScope: UInt8

    init(_ rowCounts: [64 of UInt32]) {
        func codedIndexSize<T: CodedIndexTag>(for type: T.Type) -> UInt8 {
            // 2^(16 - tagBits)
            let maxRows = 1 << (16 - type.bits)

            let needsLargeIndex = type.tables.contains {
                rowCounts[$0.rawValue] >= maxRows
            }
            return if needsLargeIndex {
                4
            } else {
                2
            }
        }

        hasConstant = codedIndexSize(for: HasConstant.Tag.self)
        hasCustomAttribute = codedIndexSize(for: HasCustomAttribute.Tag.self)
        customAttributeType = codedIndexSize(for: CustomAttributeType.Tag.self)
        hasDeclSecurity = codedIndexSize(for: HasDeclSecurity.Tag.self)
        typeDefOrRef = codedIndexSize(for: TypeDefOrRef.Tag.self)
        implementation = codedIndexSize(for: Implementation.Tag.self)
        hasFieldMarshal = codedIndexSize(for: HasFieldMarshal.Tag.self)
        typeOrMethodDef = codedIndexSize(for: TypeOrMethodDef.Tag.self)
        memberForwarded = codedIndexSize(for: MemberForwarded.Tag.self)
        memberRefParent = codedIndexSize(for: MemberRefParent.Tag.self)
        methodDefOrRef = codedIndexSize(for: MethodDefOrRef.Tag.self)
        hasSemantics = codedIndexSize(for: HasSemantics.Tag.self)
        resolutionScope = codedIndexSize(for: ResolutionScope.Tag.self)
    }
}
