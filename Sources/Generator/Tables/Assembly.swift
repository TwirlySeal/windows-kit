import BinaryParsing

struct Assembly {
    // All of the metadata within the assembly table
    let metadata: MetadataDB
    let hashAlgorithm: AssemblyHashAlgorithm
    let majorVersion UInt16
    let minorVersion UInt16
    let buildNumber: UInt16
    let revisionNumber: UInt16
    let flags: AssemblyFlags UInt32
    let publicKeyIndex: UInt32
    let typeNameIndex: UInt32
    let cultureIndex: UInt32

    // Initialisation/parsing function I guess
    init(metadata: MetadataDB, rowIndex: Int) throws {

        // set the metadata attribute as metadata
        self.metadata = metadata
        
        // All the attributes that we want to set while parsing the function
        (
            hashAlgId, 
            majorVersion,
            minorVersion,
            buildNumber,
            revisionNumber,
            flags, 
            publicKeyIndex,
            cultureIndex

        ) = try metadata.withTableSpan(for: . assembly, rowIndex: rowIndex) // metadata is all the data that we'll be reading, withTableSpan, span is the range of bits we'll be parsing
        {span in
          
            // read the raw bytes which represent HashAlgId
            let hashAlgIdRaw = try UInt32(parsingLittleEndian: &span)

            // store it in the appropriate function by parsing
            guard let hashAlgId = AssemblyHashAlgorithm(rawValue: hashAlgIdRaw) else {
                // throw parsing error if not successful
                throw ParsingError()
            }

            // parse four 2-byte (16 bit) values stored in the assembly column
            let majorVersion = try UInt16(parsingLittleEndian: &span)
            let minorVersion = try UInt16(parsingLittleEndian: &span)
            let buildNumber = try UInt16(parsingLittleEndian: &span)
            let revisionNumber = try UInt16(parsingLittleEndian: &span)

            // read raw bytes of flagsRaw
            let flagsRaw = try UInt32(parsingLittleEndian: &span)

            // try parsing it and storing it in flags variable
            guard let flags = AssemblyFlags(rawValue: flagsRaw) else {
                throw ParsingError()
            }

            // typeNameIndex and cultureIndex are strings, parse them appropriately
            let typeNameIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.ranges.heapSizes!.stringSize)
            let cultureIndex = try UInt32(parsingLittleEndian: &span, byteCount: metadata.ranges.heapSizes!.stringSize)


            // return all parsed values
            return (
                hashAlgId, 
                majorVersion,
                minorVersion, 
                buildNumber,
                revisionNumber,
                flags, 
                typeNameIndex,
                cultureIndex
            )
        }

        

    }


}