import BinaryParsing

/// A non-zero index into a table
/// An index of 0 is reserved to mean null (no index)
struct Index: RawRepresentable {
    let rawValue: UInt32
    
    init?(rawValue: RawValue) {
        if rawValue == 0 {
            return nil
        }
        self.rawValue = rawValue
    }
    
    init?(parsing span: inout ParserSpan, size: UInt8) throws {
        self.init(rawValue: try .init(parsingLittleEndian: &span, byteCount: Int(size)))
    }
}

extension Index: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Index: Strideable {
    typealias Stride = RawValue.Stride
    
    func distance(to other: Index) -> Stride {
        self.rawValue.distance(to: other.rawValue)
    }
    
    func advanced(by n: Stride) -> Index {
        let targetValue = self.rawValue.advanced(by: n)
        
        guard targetValue > 0 else {
            fatalError("Advanced out of valid Index bounds")
        }
        
        return Index(rawValue: targetValue)!
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

    init(_ rowCounts: [64 of UInt32]) {
        func indexSize(_ tableKind: TableID) -> UInt8 {
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
