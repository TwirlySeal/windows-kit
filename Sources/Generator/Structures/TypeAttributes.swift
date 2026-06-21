struct TypeAttributes {
    typealias RawValue = UInt32
    
	enum Visibility: RawValue, Maskable {
		static let mask: RawValue = 0x00000007

		case notPublic = 0x00000000
		case `public` = 0x00000001
		case nestedPublic = 0x00000002
		case nestedPrivate = 0x00000003
		case nestedFamily = 0x00000004
		case nestedAssembly = 0x00000005
		case nestedFamANDAssem = 0x00000006
		case nestedFamORAssem = 0x00000007
	}

	enum ClassLayout: RawValue, Maskable {
		static let mask: RawValue = 0x00000018

		case autoLayout = 0x00000000
		case sequentialLayout = 0x00000008
		case explicitLayout = 0x00000010
	}

	enum ClassSemantics: RawValue, Maskable {
		static let mask: RawValue = 0x00000020

		case `class` = 0x00000000
		case interface = 0x00000020
	}

	struct SpecialSemantics: OptionSet {
		let rawValue: RawValue

		static let abstract = Self(rawValue: 0x00000080)
		static let sealed = Self(rawValue: 0x00000100)
		static let specialName = Self(rawValue: 0x00000400)
	}

	struct Implementation: OptionSet {
		let rawValue: RawValue

		static let `import` = Self(rawValue: 0x00001000)
		static let serializable = Self(rawValue: 0x00002000)
	}

	enum StringFormatting: RawValue, Maskable {
		static let mask: RawValue = 0x00030000

		case ansiClass = 0x00000000
		case unicodeClass = 0x00010000
		case autoClass = 0x00020000
		case customFormatClass = 0x00030000
	}

	struct Flags: OptionSet {
		let rawValue: RawValue

		static let beforeFieldInit = 0x00100000

		static let rtSpecialName = 0x00000800
		static let hasSecurity = 0x00040000
		static let isTypeForwarder = 0x00200000
	}

	private let rawValue: RawValue

	let visibility: Visibility
	let classLayout: ClassLayout
	let classSemantics: ClassSemantics
	var specialSemantics: SpecialSemantics { .init(rawValue: rawValue) }
	var implementation: Implementation { .init(rawValue: rawValue) }
	let stringFormatting: StringFormatting
	var flags: Flags { .init(rawValue: rawValue) }

	init?(rawValue: RawValue) {
		guard
			let visibility = Visibility(masking: rawValue),
			let classLayout = ClassLayout(masking: rawValue),
			let classSemantics = ClassSemantics(masking: rawValue),
			let stringFormatting = StringFormatting(masking: rawValue)
		else {
			return nil
		}

		self.rawValue = rawValue

		self.visibility = visibility
		self.classLayout = classLayout
		self.classSemantics = classSemantics
		self.stringFormatting = stringFormatting
	}
}
