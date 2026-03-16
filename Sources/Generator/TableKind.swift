/// Raw values are the positions within bit sets such as Valid and Sorted that
/// correspond to each table
///
/// See ECMA-335 II.22 - Metadata logical format: tables
enum TableKind: Int {
	case assembly = 0x20
	case assemblyOS = 0x22
	case assemblyProcessor = 0x21
	case assemblyRef = 0x23
	case assemblyRefOS = 0x25
	case assemblyRefProcessor = 0x24
	case classLayout = 0x0F
	case constant = 0x0B
	case customAttribute = 0x0C
	case declSecurity = 0x0E
	case eventMap = 0x12
	case event = 0x14
	case exportedType = 0x27
	case field = 0x04
	case fieldLayout = 0x10
	case fieldMarshal = 0x0D
	case fieldRVA = 0x1D
	case file = 0x26
	case genericParam = 0x2A
	case genericParamConstraint = 0x2C
	case implMap = 0x1C
	case interfaceImpl = 0x09
	case manifestResource = 0x28
	case memberRef = 0x0A
	case methodDef = 0x06
	case methodImpl = 0x19
	case methodSemantics = 0x18
	case methodSpec = 0x2B
	case module = 0x00
	case moduleRef = 0x1A
	case nestedClass = 0x29
	case param = 0x08
	case property = 0x17
	case propertyMap = 0x15
	case standAloneSig = 0x11
	case typeDef = 0x02
	case typeRef = 0x01
	case typeSpec = 0x1B

	func stride(_ heapSizes: HeapSizes, _ indexSizes: IndexSizes, _ codedIndexSizes: CodedIndexSizes) -> Int {
		// Where the field name is not specified, it is the same as the table or coded index tag
		return switch self {
			case .assembly:
				4 + // HashAlgId
				2 + // MajorVersion
				2 + // MinorVersion
				2 + // BuildNumber
				2 + // RevisionNumber
				4 + // Flags
				heapSizes.blobSize + // PublicKey
				heapSizes.stringSize + // Name
				heapSizes.stringSize // Culture

			case .assemblyOS:
				4 + // OSPlatformID
				4 + // OSMajorVersion
				4 // OSMinorVersion

			case .assemblyProcessor:
				4 // Processor

			case .assemblyRef:
				2 + // MajorVersion
				2 + // MinorVersion
				2 + // BuildNumber
				2 + // RevisionNumber
				4 + // Flags
				heapSizes.blobSize + // PublicKeyOrToken
				heapSizes.stringSize + // Name
				heapSizes.stringSize + // Culture
				heapSizes.blobSize // HashValue

			case .assemblyRefOS:
				4 + // OSPlatformId
				4 + // OSMajorVersion
				4 + // OSMinorVersion
				Int(indexSizes.assemblyRef)

			case .assemblyRefProcessor:
				4 + // Processor
				Int(indexSizes.assemblyRef)

			case .classLayout:
				2 + // PackingSize
				4 + // ClassSize
				Int(indexSizes.typeDef) // Parent

			case .constant:
				1 + // Type
				1 + // padding zero
				Int(codedIndexSizes.hasConstant) + // Parent
				heapSizes.blobSize // Value

			case .customAttribute:
				Int(codedIndexSizes.hasCustomAttribute) + // Parent
				Int(codedIndexSizes.customAttributeType) + // Type
				heapSizes.blobSize // Value

			case .declSecurity:
				2 + // Action
				Int(codedIndexSizes.hasDeclSecurity) + // Parent
				heapSizes.blobSize // PermissionSet

			case .eventMap:
				Int(indexSizes.typeDef) + // Parent
				Int(indexSizes.event) // EventList

			case .event:
				2 + // EventFlags
				heapSizes.stringSize + // Name
				Int(codedIndexSizes.typeDefOrRef) // EventType

			case .exportedType:
				4 + // Flags
				4 + // TypeDefId
				heapSizes.stringSize + // TypeName
				heapSizes.stringSize + // TypeNamespace
				Int(codedIndexSizes.implementation)

			case .field:
				2 + // Flags
				heapSizes.stringSize + // Name
				heapSizes.blobSize // Signature

			case .fieldLayout:
				4 + // Offset
				Int(indexSizes.field)

			case .fieldMarshal:
				Int(codedIndexSizes.hasFieldMarshal) + // Parent
				heapSizes.blobSize // NativeType

			case .fieldRVA:
				4 + // RVA
				Int(indexSizes.field)

			case .file:
				4 + // Flags
				heapSizes.stringSize + // Name
				heapSizes.blobSize // HashValue

			case .genericParam:
				2 + // Number
				2 + // Flags
				Int(codedIndexSizes.typeOrMethodDef) + // Owner
				heapSizes.stringSize // Name

			case .genericParamConstraint:
				Int(indexSizes.genericParam) + // Owner
				Int(codedIndexSizes.typeDefOrRef) // Constraint

			case .implMap:
				2 + // MappingFlags
				Int(codedIndexSizes.memberForwarded) +
				heapSizes.stringSize + // ImportName
				Int(indexSizes.moduleRef) // ImportScope

			case .interfaceImpl:
				Int(indexSizes.typeDef) + // Class
				Int(codedIndexSizes.typeDefOrRef) // Interface

			case .manifestResource:
				4 + // Offset
				4 + // Flags
				heapSizes.stringSize + // Name
				Int(codedIndexSizes.implementation)

			case .memberRef:
				Int(codedIndexSizes.memberRefParent) + // Class
				heapSizes.stringSize + // Name
				heapSizes.blobSize // Signature

			case .methodDef:
				4 + // RVA
				2 + // ImplFlags
				2 + // Flags
				heapSizes.stringSize + // Name
				heapSizes.blobSize + // Signature
				Int(indexSizes.param) // ParamList

			case .methodImpl:
				Int(indexSizes.typeDef) + // Class
				Int(codedIndexSizes.methodDefOrRef) + // MethodBody
				Int(codedIndexSizes.methodDefOrRef) // MethodDeclaration

			case .methodSemantics:
				2 + // Semantics
				Int(indexSizes.methodDef) + // Method
				Int(codedIndexSizes.hasSemantics) // Association

			case .methodSpec:
				Int(codedIndexSizes.methodDefOrRef) + // Method
				heapSizes.blobSize // Instantiation

			case .module:
				2 + // Generation
				heapSizes.stringSize + // Name
				heapSizes.guidSize + // Mvid
				heapSizes.guidSize + // EncId
				heapSizes.guidSize // EncBaseId

			case .moduleRef:
				heapSizes.stringSize // Name

			case .nestedClass:
				Int(indexSizes.typeDef) + // NestedClass
				Int(indexSizes.typeDef) // EnclosingClass

			case .param:
				2 + // Flags
				2 + // Sequence
				heapSizes.stringSize // Name

			case .property:
				2 + // Flags
				heapSizes.stringSize + // Name
				heapSizes.blobSize // Type

			case .propertyMap:
				Int(indexSizes.typeDef) + // Parent
				Int(indexSizes.property) // PropertyList

			case .standAloneSig:
				heapSizes.blobSize

			case .typeDef:
				4 + // Flags
				heapSizes.stringSize + // TypeName
				heapSizes.stringSize + // TypeNamespace
				Int(codedIndexSizes.typeDefOrRef) + // Extends
				Int(indexSizes.field) + // FieldList
				Int(indexSizes.methodDef) // MethodList

			case .typeRef:
				Int(codedIndexSizes.resolutionScope) +
				heapSizes.stringSize + // TypeName
				heapSizes.stringSize // TypeNamespace

			case .typeSpec:
				heapSizes.blobSize // Signature
		}
	}
}

struct IndexSizes {
	let assemblyRef: UInt8
	let typeDef: UInt8
	let event: UInt8
	let field: UInt8
	let genericParam: UInt8
	let moduleRef: UInt8
	let param: UInt8
	let methodDef: UInt8
	let property: UInt8

	init(_ rowCounts: TableSlots<UInt32>) {
		func indexSize(_ tableKind: TableKind) -> UInt8 {
			let rowCount = rowCounts[tableKind.rawValue]
			return if rowCount <= UInt16.max {
				2
			} else {
				4
			}
		}

		assemblyRef = indexSize(.assemblyRef)
		typeDef = indexSize(.typeDef)
		event = indexSize(.event)
		field = indexSize(.field)
		genericParam = indexSize(.genericParam)
		moduleRef = indexSize(.moduleRef)
		param = indexSize(.param)
		methodDef = indexSize(.methodDef)
		property = indexSize(.property)
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

	init(_ rowCounts: TableSlots<UInt32>) {
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

		hasConstant = codedIndexSize(for: HasConstant.self)
		hasCustomAttribute = codedIndexSize(for: HasCustomAttribute.self)
		customAttributeType = codedIndexSize(for: CustomAttributeType.self)
		hasDeclSecurity = codedIndexSize(for: HasDeclSecurity.self)
		typeDefOrRef = codedIndexSize(for: TypeDefOrRef.self)
		implementation = codedIndexSize(for: Implementation.self)
		hasFieldMarshal = codedIndexSize(for: HasFieldMarshal.self)
		typeOrMethodDef = codedIndexSize(for: TypeOrMethodDef.self)
		memberForwarded = codedIndexSize(for: MemberForwarded.self)
		memberRefParent = codedIndexSize(for: MemberRefParent.self)
		methodDefOrRef = codedIndexSize(for: MethodDefOrRef.self)
		hasSemantics = codedIndexSize(for: HasSemantics.self)
		resolutionScope = codedIndexSize(for: ResolutionScope.self)
	}
}
