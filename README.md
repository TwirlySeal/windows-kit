# Windows Kit

The goal of this project is to provide an idiomatic Swift language projection of
Windows APIs.

To be able to call Windows APIs from Swift, we need to speak their ABI
(Application Binary Interface) which defines how compiled programs can talk to
each other. There are 3 main ABIs used on Windows:

1.  The C programming language ABI, used by the low-level Win32 API

2.  COM (Component Object Model), which adds object-oriented constructs on top
    of the C ABI

3.  WinRT (Windows Runtime), which is based on COM but adds additional metadata
    to enable automatic generation of safe, idiomatic bindings

Microsoft’s [win32metadata](https://github.com/microsoft/win32metadata) project
also provides metadata for Win32 and COM APIs.

Metadata is stored in
[WinMD](https://learn.microsoft.com/en-us/uwp/winrt-cref/winmd-files) (Windows
Metadata) files, which use the same binary format as .NET assemblies
([ECMA-335](https://ecma-international.org/wp-content/uploads/ECMA-335_6th_edition_june_2012.pdf))
and are distributed via NuGet packages:

- Win32:
  [Microsoft.Windows.SDK.Win32Metadata](https://www.nuget.org/packages/Microsoft.Windows.SDK.Win32Metadata)

- Win32 (Drivers):
  [Microsoft.Windows.WDK.Win32Metadata](https://www.nuget.org/packages/Microsoft.Windows.WDK.Win32Metadata)

- WinRT:
  [Microsoft.Windows.SDK.Contracts](https://www.nuget.org/packages/Microsoft.Windows.SDK.Contracts)

This project downloads and parses these files and generates Swift code for the
APIs they describe. The generated Swift code implements the ABIs and maps
Windows API constructs to equivalent Swift ones, such as Swift concurrency and
errors. It will be distributed as libraries that anyone can use to develop
Windows apps using Swift.

## Currently Implemented Features

- Downloads Windows Metadata from the NuGet Server API and caches it locally

- A WinMD parser made with [Swift Binary
  Parsing](https://apple.github.io/swift-binary-parsing/documentation/binaryparsing/)

- A ZIP format parser (also made with Swift Binary Parsing) and Deflate
  decompressor for extracting `.nupkg` files from NuGet containing the metadata
  (these could be good to turn into separate libraries)
