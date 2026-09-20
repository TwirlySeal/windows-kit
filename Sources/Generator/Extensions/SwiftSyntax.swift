import SwiftSyntax

extension SyntaxProtocol {
    func write(to stream: inout FileOutputStream) throws {
        for token in self.tokens(viewMode: .sourceAccurate) {
            for piece in token.leadingTrivia {
                try piece.write(to: &stream)
            }
            
            try stream.write(token.text)
            
            for piece in token.trailingTrivia {
                try piece.write(to: &stream)
            }
        }
    }
}

extension TriviaPiece {
    func write(to stream: inout FileOutputStream) throws {
        func printRepeated(
            _ character: String,
            count: Int
        ) throws {
          for _ in 0 ..< count {
            try stream.write(character)
          }
        }
        
        switch self {
        case let .backslashes(count):
            try printRepeated(#"\"#, count: count)
        case let .carriageReturns(count):
          try printRepeated("\r", count: count)
        case let .carriageReturnLineFeeds(count):
          try printRepeated("\r\n", count: count)
        case let .formfeeds(count):
          try printRepeated("\u{c}", count: count)
        case let .newlines(count):
          try printRepeated("\n", count: count)
        case let .pounds(count):
          try printRepeated("#", count: count)
        case let .spaces(count):
          try printRepeated(" ", count: count)
        case let .tabs(count):
          try printRepeated("\t", count: count)
        case let .verticalTabs(count):
          try printRepeated("\u{b}", count: count)
        case let .lineComment(text),
             let .blockComment(text),
             let .docLineComment(text),
             let .docBlockComment(text),
             let .unexpectedText(text):
          try stream.write(text)
        }
    }
}
