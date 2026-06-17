// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause
// Adapted from https://github.com/compnerd/dft/

// Dynamic Huffman Constants

/// Base offsets for dynamic Huffman tree specifications (RFC 1951 §3.2.7).
let HLITBase = 257
let HDISTBase = 1
let HCLENBase = 4
let codeLengthAlphabetSize = 19

/// Code length order for dynamic Huffman tables (RFC 1951 §3.2.7).
///
/// Lengths are stored in this scrambled order to maximize runs of zeros at the end,
/// allowing the encoder to omit trailing zero-length codes for better compression.
let codeLengthOrder: InlineArray<_, Int> = [
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

// LZ77 Tables

typealias TableTuple = (base: UInt16, extra: UInt8)

/// Length code table (RFC 1951 §3.2.5).
///
/// Maps length codes (257-285) to base length values and extra bits.
let lengthCodeTable: InlineArray<_, TableTuple> = [
    (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),  // 257-264
    (11, 1), (13, 1), (15, 1), (17, 1),  // 265-268
    (19, 2), (23, 2), (27, 2), (31, 2),  // 269-272
    (35, 3), (43, 3), (51, 3), (59, 3),  // 273-276
    (67, 4), (83, 4), (99, 4), (115, 4),  // 277-280
    (131, 5), (163, 5), (195, 5), (227, 5), (258, 0),  // 281-285
]

/// Distance code table (RFC 1951 §3.2.5).
///
/// Maps distance codes (0-29) to base distance values and extra bits.
let distanceCodeTable: InlineArray<_, TableTuple> = [
    (1, 0), (2, 0), (3, 0), (4, 0),  // 0-3
    (5, 1), (7, 1), (9, 2), (13, 2),  // 4-7
    (17, 3), (25, 3), (33, 4), (49, 4),  // 8-11
    (65, 5), (97, 5), (129, 6), (193, 6),  // 12-15
    (257, 7), (385, 7), (513, 8), (769, 8),  // 16-19
    (1025, 9), (1537, 9), (2049, 10), (3073, 10),  // 20-23
    (4097, 11), (6145, 11), (8193, 12), (12289, 12),  // 24-27
    (16385, 13), (24577, 13),  // 28-29
]

// Fixed Huffman Trees

/// Fixed literal/length code lengths (RFC 1951 §3.2.6).
///
/// Canonical Huffman code lengths for fixed encoding:
func fixedLiteralLength(for value: Int) -> Int {
    switch value {
        case 0...143: 8
        
        case 144...255: 9
        
        case 256...279: 7
        
        case 280...287: 8
        
        default:
            fatalError("Literal/length value out of range")
    }
}

let fixedDistanceLength = 5
