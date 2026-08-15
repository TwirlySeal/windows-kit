# Windows Kit

The goal of this project is to let you call Windows APIs from Swift and make
them behave like native Swift code, complete with Swift concurrency and error
handling. This is accomplished by generating a *language projection*: bindings
that map Windows API concepts to equivalent Swift ones. These bindings will be
distributed as libraries that anyone can use to develop Windows apps using
Swift.

Windows APIs provided by this project will include:

- [Windows SDK](https://learn.microsoft.com/en-us/windows/apps/windows-sdk/)

- [Windows App
  SDK](https://learn.microsoft.com/en-us/windows/apps/windows-app-sdk/)

- Windows Driver Kit (WDK)

## How it works

To be able to call Windows APIs from Swift, we need to speak their **ABI**
(Application Binary Interface) which defines how compiled programs can talk to
each other. There are 3 main ABIs used on Windows:

1.  The **C** programming language ABI, used by classic Win32 APIs and newer
    APIs that need low level control like
    [IORing](https://learn.microsoft.com/en-us/windows/win32/api/ioringapi/).

2.  **COM** (Component Object Model), which adds object-oriented constructs and
    reference counting on top of the C ABI. At the time, Microsoft’s MSVC
    compiler for C++ lacked ABI stability, meaning binaries compiled with one
    version could not call those compiled with another. Other C++ compilers with
    their own incompatible ABIs were also commonly used in Windows development.
    COM was designed to be a stable subset of the MSVC C++ ABI that could serve
    as a standard for interoperability between different C++ compilers and other
    languages like Delphi and Visual Basic. COM is used by Win32 APIs like
    DirectX and the Windows Shell API.

3.  **WinRT** (Windows Runtime), which is based on COM but adds additional
    metadata to enable automatic generation of bindings for any programming
    language. WinRT is used by modern, high-level Windows APIs for tasks such as
    notifications and UI.

Microsoft’s [win32metadata](https://github.com/microsoft/win32metadata) project
also provides projection metadata for C and COM APIs.

Metadata for Windows APIs is stored in Windows Metadata (WinMD) files, which are
explained in the docs for this project [here](docs/windows-metadata.md). These
metadata files are distributed via NuGet packages:

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

We can download and parse these files to generate code for a language projection
that defines the APIs and implements their ABIs. C headers will be generated for
C APIs, while C++ headers will be generated for COM and WinRT because of their
basis on a subset of the MSVC C++ ABI. These headers will include Clang
attributes that allow the Swift compiler to import the APIs with a more
Swift-friendly interface, and we will also generate Swift wrappers where needed
to further improve the interface.

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
