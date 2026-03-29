# Binary Parsing

Binary formats are not human readable, meaning we must parse them using code to
discover the information inside. We use a library called Swift Binary Parsing to
do this.

Resource: [Getting Started with
BinaryParsing](https://apple.github.io/swift-binary-parsing/documentation/binaryparsing/gettingstarted)

# CLI metadata format

Unless otherwise stated, the format is in little endian.

There are two ways metadata is stored in WinMD files:

1.  Tables (arrays of records)

2.  Heaps

# Tables

> See ‘II.22 Metadata logical format: tables’ for more information

A table has a variable number of rows with a defined set of columns. The size of
each row is known, so we can multiply it by a row index to get the offset for
that row. This allows table rows to link to each other using indices for O(1)
lookups.

![Table structure diagram](./tables.svg)

There are two types of columns in table rows:

1.  Constant - A literal value or bitmask

2.  Index - An index to a row in the same or another table.

A bitmask constant stores multiple pieces of information in each byte, each of
which can be accessed using a bitmask that isolates the bits of interest.

There are two types of indices:

1.  Simple - an index into one, and only one, table
2.  Coded - an index into one of several tables. A few bits of the index value
    are reserved to define which table it targets.

# Heaps

> See ‘II.24.2.2 Stream header’ for more information.

Heaps are variable-length data regions where data is accessed via a byte offset.
The length or end of data in a heap is needed to know where to stop reading.

## String heap

The string heap contains null-terminated UTF-8 strings.

![Heap structure diagram](./heap.svg)

## Blob heap

The blob heap stores variable-length data in non-normalised, contiguous binary
objects called blobs. A blob stores its length in the first few bytes.

For example, method signatures describe the types of parameters of a method and
the type of its return value. They are stored in blobs because they can have any
number of parameters and cannot fit in a fixed-size table row.

The length prefix of blobs and integers within signatures are compressed using a
variable-length encoding; the first few bits signal the total byte length of the
number so that smaller numbers can be represented using fewer bytes. Compressed
integers are encoded in big-endian (i.e. with the most significant byte at the
smallest offset within the file) so that the length bits can be read first.

# Notation

> See ‘§II.5 General Syntax’ for more information.

The spec uses a modified form of the [Backus-Naur
form](https://en.wikipedia.org/wiki/Backus–Naur_form) syntax notation to
describe the structure of signatures. Here is a summary:

- `::=` means “is defined as”

- `|` means OR

- `*` means one or more of the preceding element

The spec also uses [Syntax
Diagrams](https://en.wikipedia.org/wiki/Syntax_diagram).

- Parallel tracks represent alternatives

- Looped tracks mean one or more
