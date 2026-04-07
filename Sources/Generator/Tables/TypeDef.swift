import BinaryParsing

struct TypeDef {
	let metadata: MetadataDB
	let flags: TypeAttributes
	private let typeNameIndex: UInt32
	
	init(metadata: MetadataDB, rowIndex: Int) throws {
		self.metadata = metadata
		
		(flags, typeNameIndex) = try metadata.withRowSpan(in: .typeDef, rowIndex: rowIndex) { span in
			guard
				let flags = TypeAttributes(rawValue: try UInt32(parsingLittleEndian: &span))
			else {
				throw ParsingError()
			}

			let typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.ranges.heapSizes!.stringSize)

			return (
				flags,
				typeNameIndex
			)
		}
	}
}
