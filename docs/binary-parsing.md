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

> See ‘§II.22 Metadata logical format: tables’ for more information

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

## The `Index` type

Indices to tables are 1-based because an index of zero is reserved to mean a
null index that does not index a row at all. To make this safer, I applied the
[“parse, don’t
validate”](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)
idiom by Alexis King:

- Validation (the brittle way): Checking `if index == 0` at the point of use. If
  you forget the check, the code still compiles, but breaks at runtime when you
  resolve the index.

- Parsing (the robust way): I made an `Index` type which conforms to
  [`RawRepresentable`](https://developer.apple.com/documentation/swift/rawrepresentable)
  and has a failable initializer that returns nil when the raw value is 0. Now,
  checks are moved to the boundaries of the program where indices are
  constructed from raw values, and you cannot use it to look up a row without
  the compiler forcing you to acknowledge the possibility of absence. Once those
  checks have been performed, they never need to be checked again. The type
  itself (`Index` vs `Optional<Index>`) proves the value is non-zero.

`Index` also conforms to `Strideable` so ranges of indices can be represented
with the same safety.

## List columns

ECMA-335 defines ‘list’ columns where in a given table X it is equal to an index
into another table Y. This index marks the first of a contiguous run of rows in
table Y owned by this row in table X. The run continues to the smaller of:

- the last row of table Y

- the next run of table Y rows, found by inspecting the same list column of the
  next row in table X

Examples include the `FieldList` and `MethodList` columns in ‘§II.22.37
TypeDef’.

Some list columns, such as the above examples, are allowed to be null by the
spec. In this scenario, a parser would need to scan to find the next row in
table X with a non-null index for the same list column, not just inspect the
next row. However, Windows Metadata does not use null indices for list columns,
instead using an index equal to the index of the next row to mean an empty
range. This is evidenced by windows-rs which assumes the list column of the next
row is non-null
([source](https://github.com/microsoft/windows-rs/blob/a1e9fce43c026221f62f0a149267cb6d7d3c607b/crates/libs/metadata/src/reader/file.rs#L523-L538)).

I did not consider this edge case when originally writing the list function
using raw `Int` indices, until I introduced the `Index` type and the compiler
revealed that the list column in the next row could be null. This shows how
encoding constraints in the type system allows the compiler to reveal logical
consequences you have not considered. While this edge case will not arise in
Windows Metadata, I made the parser handle it because it is a neat find.

## Bitmask constants

Some columns are structures containing multiple pieces of information in their
bit width, which can be isolated using bitmasks. These are defined in ‘§II.23.1
Bitmasks and flags’, and `TypeAttributes` is an example.

There are two kinds of information stored in bitmask constants:

1.  Bit flags, which are independent. I found structs implementing the
    [`OptionSet`](https://developer.apple.com/documentation/swift/optionset)
    protocol are effective for representing these.

2.  Multi-bit segments which have a closed set of mutually exclusive values.
    These are best represented as enums with raw values, and I made a `Maskable`
    protocol which uses a static `mask` property to provide a default `masking`
    initializer that applies the bitmask and uses the resulting value as the raw
    value.

Most structures contain multiple option sets and enums, so each type is nested
inside a greater struct where values of these types are available as properties.
The outer struct has a failable initialiser that returns nil if any of the
mutually exclusive values don’t match the defined enums. The usage site can then
decide whether the nil case is an error.

`OptionSet` fields are computed properties initialised from a single `rawValue`
field, since they don’t fail. Enum fields are stored which duplicates
information, but this keeps handling of the nil case in the initialiser instead
of computed properties.

# Heaps

> See ‘§II.24.2.2 Stream header’ for more information.

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
