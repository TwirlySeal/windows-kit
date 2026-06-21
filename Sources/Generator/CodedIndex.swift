/// A coded index is an index into one of multiple possible tables
///
/// See ECMA-335 II.24.2.6, page 274
protocol CodedIndexTag: RawRepresentable where RawValue: FixedWidthInteger {
	/// The number of bits used to encode the tag.
	static var bits: Int { get }

	// The tables that the index may point into.
	static var tables: [TableKind] { get }
}

struct CodedIndex<Tag: CodedIndexTag> {
    let tag: Tag
    let index: Tag.RawValue
    
    init?(rawValue: Tag.RawValue) throws {
        let mask: Tag.RawValue = (1 << Tag.bits) - 1
        let tagBits = rawValue & mask
        guard let tag = Tag.init(rawValue: tagBits) else {
            throw MetadataError.invalidCodedIndexTag
        }
        
        let index = rawValue >> Tag.bits
        if index == 0 { return nil }
        
        self.tag = tag
        self.index = index
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
