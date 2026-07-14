# Windows Kit

The goal of this project is to let you call Windows APIs from Swift and make
them behave like native Swift code, complete with Swift concurrency and error
handling. This is accomplished by generating a *language projection*: bindings
that map Windows API concepts to equivalent Swift ones. These bindings will be
distributed as libraries that anyone can use to develop Windows apps using
Swift.

Windows APIs provided by this project will include:

- [Windows SDK](https://learn.microsoft.com/en-us/windows/apps/windows-sdk/)

- Windows Driver Kit (WDK)

- [Windows App
  SDK](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/)

## How it works

To be able to call Windows APIs from Swift, we need to speak their **ABI**
(Application Binary Interface) which defines how compiled programs can talk to
each other. There are 3 main ABIs used on Windows:

1.  The **C** programming language ABI, used by the low-level Win32 API

2.  **COM** (Component Object Model), which adds object-oriented constructs on
    top of the C ABI

3.  **WinRT** (Windows Runtime), which is based on COM but adds additional
    metadata to enable automatic generation of safe, idiomatic bindings

Microsoft’s [win32metadata](https://github.com/microsoft/win32metadata) project
also provides metadata for Win32 and COM APIs.

Metadata is stored in
[WinMD](https://learn.microsoft.com/en-us/uwp/winrt-cref/winmd-files) (Windows
Metadata) files, which use the same binary format as .NET assemblies
([ECMA-335](https://ecma-international.org/wp-content/uploads/ECMA-335_6th_edition_june_2012.pdf))
and are distributed via NuGet packages:

- Windows SDK (Win32):
  [Microsoft.Windows.SDK.Win32Metadata](https://www.nuget.org/packages/Microsoft.Windows.SDK.Win32Metadata)

- Windows Driver Kit (Win32):
  [Microsoft.Windows.WDK.Win32Metadata](https://www.nuget.org/packages/Microsoft.Windows.WDK.Win32Metadata)

- Windows SDK (WinRT):
  [Microsoft.Windows.SDK.Contracts](https://www.nuget.org/packages/Microsoft.Windows.SDK.Contracts)

- Windows App SDK (WinRT):
  [Microsoft.WindowsAppSDK](https://www.nuget.org/packages/Microsoft.WindowsAppSDK)

  - This package includes both the metadata and C++ implementation

  - Some C, C++, and COM APIs without WinRT metadata are also included

We can download and parse these files to generate C/C++ headers that define the
APIs and hide the ABI details. These headers will include Clang attributes that
allow the Swift compiler to import the APIs with a more Swift-friendly
interface, and we will also generate Swift wrappers where needed to further
improve the interface.

## Projection Generator Features

- Pure Swift

- Works on Windows, macOS, and Linux

- A WinMD parser made with [Swift Binary
  Parsing](https://swiftpackageindex.com/apple/swift-binary-parsing)

  - Only the subset of ECMA-335 used by Windows Metadata is implemented, which
    greatly reduces complexity

- Downloads Windows Metadata packages from the NuGet Server API in `.nupkg`
  format (which is just a renamed `.zip` file) and caches the metadata files
  locally

- A ZIP format parser also made with Swift Binary Parsing (used to extract the
  NuGet packages)

- A Deflate decompressor (used in the ZIP parser) made with a `BitSpan`
  non-copyable LSB bit reader inspired by `ParserSpan` from Swift Binary Parsing
  and a two-level lookup table for Huffman decoding like zlib

> The ZIP parser, Deflate decompressor, and `BitSpan` could be good to make
> available as separate libraries
