//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import StructuredHeaders

struct BareItemDecoder<BaseData: RandomAccessCollection> where BaseData.Element == UInt8, BaseData.SubSequence == BaseData, BaseData: Hashable {
    private var item: BareItem<BaseData>

    private var _codingPath: [_StructuredHeaderCodingKey]

    init(_ item: BareItem<BaseData>, codingPath: [_StructuredHeaderCodingKey]) {
        self.item = item
        self._codingPath = codingPath
    }
}

extension BareItemDecoder: SingleValueDecodingContainer {
    var codingPath: [CodingKey] {
        return self._codingPath as [CodingKey]
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try self._decodeFixedWidthInteger(type)
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try self._decodeBinaryFloatingPoint(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try self._decodeBinaryFloatingPoint(type)
    }

    func decode(_ type: String.Type) throws -> String {
        switch item {
        case .string(let string):
            return string
        case .token(let token):
            return token
        default:
            throw StructuredHeaderError.invalidTypeForItem
        }
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        guard case .bool(let bool) = self.item else {
            throw StructuredHeaderError.invalidTypeForItem
        }

        return bool
    }

    func decodeNil() -> Bool {
        // Items are never nil.
        return false
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is UInt8.Type:
            return try self.decode(UInt8.self) as! T
        case is Int8.Type:
            return try self.decode(Int8.self) as! T
        case is UInt16.Type:
            return try self.decode(UInt16.self) as! T
        case is Int16.Type:
            return try self.decode(Int16.self) as! T
        case is UInt32.Type:
            return try self.decode(UInt32.self) as! T
        case is Int32.Type:
            return try self.decode(Int32.self) as! T
        case is UInt64.Type:
            return try self.decode(UInt64.self) as! T
        case is Int64.Type:
            return try self.decode(Int64.self) as! T
        case is UInt.Type:
            return try self.decode(UInt.self) as! T
        case is Int.Type:
            return try self.decode(Int.self) as! T
        case is Float.Type:
            return try self.decode(Float.self) as! T
        case is Double.Type:
            return try self.decode(Double.self) as! T
        case is String.Type:
            return try self.decode(String.self) as! T
        case is Bool.Type:
            return try self.decode(Bool.self) as! T
        default:
            // Some other codable type. Not sure what to do here yet.
            // TODO: What about binary data here? For now we'll ignore it.
            throw StructuredHeaderError.invalidTypeForItem
        }
    }

    private func _decodeBinaryFloatingPoint<T: BinaryFloatingPoint>(_ type: T.Type) throws -> T {
        guard case .decimal(let decimal) = self.item else {
            throw StructuredHeaderError.invalidTypeForItem
        }

        // Going via Double is a bit sad. Swift Numerics would help here.
        return T(Double(decimal))
    }

    private func _decodeFixedWidthInteger<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        guard case .integer(let int) = self.item else {
            throw StructuredHeaderError.invalidTypeForItem
        }

        guard let result = T(exactly: int) else {
            throw StructuredHeaderError.integerOutOfRange
        }

        return result
    }
}