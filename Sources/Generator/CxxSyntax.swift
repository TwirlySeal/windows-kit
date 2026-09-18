import Foundation

// DSL for generating formatted C and C++ code
// Inspired by SwiftSyntax

struct BasicFormat {
    var level: Int = 0
    let handle: FileHandle
    
    static let indentWidth = 4
    
    mutating func write(_ string: String) throws {
        if let data = string.data(using: .utf8) {
            try handle.write(contentsOf: data)
        }
    }
    
    mutating func writeLine(_ text: String? = nil) throws {
        if let text {
            try writeIndentation()
            try write(text)
        }
        try write("\n")
    }
    
    mutating func writeIndentation() throws {
        let indentation = String(repeating: " ", count: level * Self.indentWidth)
        try write(indentation)
    }
    
    mutating func indented<E>(_ body: (inout Self) throws(E) -> Void) throws(E) {
        level += 1
        try body(&self)
        level -= 1
    }
}

protocol CxxSyntax {
    func write(to format: inout BasicFormat) throws
}

struct CxxBlock: CxxSyntax {
    let components: [any CxxSyntax]

    func write(to format: inout BasicFormat) throws {
        for component in components {
            try component.write(to: &format)
        }
    }
}

@resultBuilder
enum CxxSyntaxBuilder {
    static func buildBlock(_ components: any CxxSyntax...) -> any CxxSyntax {
        CxxBlock(components: components)
    }
    
    static func buildArray(_ components: [any CxxSyntax]) -> any CxxSyntax {
        CxxBlock(components: components)
    }

    static func buildOptional(_ component: any CxxSyntax?) -> any CxxSyntax {
        component ?? CxxBlock(components: [])
    }

    static func buildEither(first component: any CxxSyntax) -> any CxxSyntax {
        component
    }

    static func buildEither(second component: any CxxSyntax) -> any CxxSyntax {
        component
    }
}


struct CppStruct: CxxSyntax {
    let name: String
    let members: any CxxSyntax
    
    init(name: String, @CxxSyntaxBuilder _ members: () -> any CxxSyntax) {
        self.name = name
        self.members = members()
    }

    func write(to format: inout BasicFormat) throws {
        try format.writeLine("struct \(name) {")
        try format.indented { format in
            try members.write(to: &format)
        }
        try format.writeLine("};")
    }
}

struct CFunctionDecl: CxxSyntax {
    let name: String
    var returnType: String = "void"
    var parameters: [String] = []

    func write(to format: inout BasicFormat) throws {
        let params = parameters.joined(separator: ", ")
        try format.writeLine("\(returnType) \(name)(\(params));")
    }
}
