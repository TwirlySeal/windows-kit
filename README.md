# Windows Kit

The goal of this project is to provide idiomatic bindings to Windows APIs for
the [Swift](https://swift.org/) programming language.

To be able to call Windows APIs from Swift, we need to speak their ABI
(Application Binary Interface) which defines how compiled programs can talk to
each other. There are 3 main ABIs used on Windows:

1.  The C programming language ABI, used by the low-level Win32 API

2.  COM (Component Object Model), which adds object-oriented constructs on top
    of the C ABI

3.  WinRT (Windows Runtime), which is based on COM but adds additional metadata
    to enable automatic generation of safe, idiomatic bindings

We will be starting with modern Windows APIs based on WinRT, such as [WinUI
3](https://learn.microsoft.com/en-us/windows/apps/winui/winui3/).

WinRT APIs are described in
[WinMD](https://learn.microsoft.com/en-us/uwp/winrt-cref/winmd-files) (Windows
Metadata) files, which are encoded in a binary format called CLI metadata. We
will parse these files according to the [format
specification](https://ecma-international.org/wp-content/uploads/ECMA-335_6th_edition_june_2012.pdf)
and use the metadata to generate Swift definitions for the APIs they describe.

This generated Swift code will be distributed as a library that anyone can use
to develop Windows apps using Swift.

## Swift resources

- [Getting Started \|
  Swift.org](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/thebasics/)

- [Enumerations](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations)

- [Closures](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures)

- [Structures and
  Classes](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures)

- [Protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols)

- [Swift Binary Parsing
  Documentation](https://apple.github.io/swift-binary-parsing/documentation/binaryparsing/)
  (this is the library we are using to parse CLI metadata)
