import BinaryParsing

extension Array {
    init<E: Error>(count: Int, element: () throws(E) -> Element) throws(E) {
        self.init()
        self.reserveCapacity(count)
        for _ in 0..<count {
            self.append(try element())
        }
    }
}

enum Ordering {
    case lessThan
    case equal
    case greaterThan
}

extension Comparable {
    func compare(to other: Self) -> Ordering {
        if self < other { return .lessThan }
        if self > other { return .greaterThan }
        return .equal
    }
}

extension Float {
  init(parsingLittleEndian input: inout ParserSpan) throws {
    let tmp = try UInt32(parsingLittleEndian: &input)
    self = Float(bitPattern: tmp)
  }
}

extension Double {
  init(parsingLittleEndian input: inout ParserSpan) throws {
    let tmp = try UInt64(parsingLittleEndian: &input)
    self = Double(bitPattern: tmp)
  }
}
