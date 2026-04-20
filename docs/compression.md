# Compression

Compression is the process of identifying repeated patterns in data and using
shorter symbols to represent them. It relies on a **codebook** that allows a
decompressor to translate these symbols back into the original data. This
codebook may be statically defined by the specification or dynamic, where a
codebook is generated specifically for the data and included as metadata within
the compressed output.

# Huffman coding

[Huffman Coding](https://www.youtube.com/watch?v=JsTptu56GM8) assigns
variable-length codes to source symbols, such that the most frequent symbols
have the shortest codes (to minimise size) and no code is a prefix of another
code (to prevent ambiguity when decoding).

A standard Huffman codebook is represented as pairs of source symbols and codes.

## Canonical Huffman coding

Canonical Huffman coding reduces the size of the codebook by only storing the
length (in bits) of the code for each symbol. Each symbol and code can be
determined from this information.
