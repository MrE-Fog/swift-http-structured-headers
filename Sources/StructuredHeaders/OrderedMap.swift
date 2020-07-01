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

/// OrderedMap is a data type that has associative-array properties, but that
/// maintains insertion order.
///
/// Our initial implementation takes advantage of the fact that the vast majority of
/// maps in structured headers are small (fewer than 20 elements), and so the
/// distinction between hashing and linear search is not really a concern. However, for
/// future implementation flexibility, we continue to require that keys be hashable.
struct OrderedMap<Key, Value> where Key: Hashable {
    private var backing: [Entry]

    init() {
        self.backing = []
    }

    /// Look up the value for a given key.
    ///
    /// Warning! Unlike a regular dictionary, we do not promise this will be O(1)!
    subscript(key: Key) -> Value? {
        get {
            return self.backing.first(where: { $0.key == key }).map { $0.value }
        }
        set {
            if let existing = self.backing.firstIndex(where: { $0.key == key }) {
                self.backing.remove(at: existing)
            }
            if let newValue = newValue {
                self.backing.append(Entry(key: key, value: newValue))
            }
        }
    }
}

// MARK:- Helper struct for storing elements
extension OrderedMap {
    // This struct takes some explaining.
    //
    // We don't want to maintain too much code here. In particular, we'd like to have straightforward equatable and hashable
    // implementations. However, tuples aren't equatable or hashable. So we need to actually store something that is: a nominal
    // type. That's this!
    //
    // This existence of this struct is a pure implementation detail and not exposed to the user of the type.
    fileprivate struct Entry {
        var key: Key
        var value: Value
    }
}

// MARK:- Collection conformances
extension OrderedMap: RandomAccessCollection, MutableCollection {
    struct Index {
        fileprivate var baseIndex: Array<(Key, Value)>.Index

        fileprivate init(_ baseIndex: Array<(Key, Value)>.Index) {
            self.baseIndex = baseIndex
        }
    }

    var startIndex: Index {
        return Index(self.backing.startIndex)
    }

    var endIndex: Index {
        return Index(self.backing.endIndex)
    }

    var count: Int {
        return self.backing.count
    }

    subscript(position: Index) -> (Key, Value) {
        get {
            let element = self.backing[position.baseIndex]
            return (element.key, element.value)
        }
        set {
            self.backing[position.baseIndex] = Entry(key: newValue.0, value: newValue.1)
        }
    }

    func index(_ i: Index, offsetBy distance: Int) -> Index {
        return Index(self.backing.index(i.baseIndex, offsetBy: distance))
    }

    func index(after i: Index) -> Index {
        return self.index(i, offsetBy: 1)
    }

    func index(before i: Index) -> Index {
        return self.index(i, offsetBy: -1)
    }
}

extension OrderedMap.Index: Hashable { }

extension OrderedMap.Index: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.baseIndex < rhs.baseIndex
    }
}

extension OrderedMap.Index: Strideable {
    func advanced(by n: Int) -> Self {
        return Self(self.baseIndex.advanced(by: n))
    }

    func distance(to other: Self) -> Int {
        return self.baseIndex.distance(to: other.baseIndex)
    }
}

// MARK:- Helper conformances
extension OrderedMap: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (Key, Value)...) {
        self.backing = elements.map { Entry(key: $0.0, value: $0.1) }
    }
}

extension OrderedMap: CustomDebugStringConvertible {
    var debugDescription: String {
        let backingRepresentation = self.backing.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        return "[\(backingRepresentation)]"
    }
}

// MARK:- Conditional conformances
extension OrderedMap.Entry: Equatable where Key: Equatable, Value: Equatable { }
extension OrderedMap: Equatable where Key: Equatable, Value: Equatable { }
extension OrderedMap.Entry: Hashable where Key: Hashable, Value: Hashable { }
extension OrderedMap: Hashable where Key: Hashable, Value: Hashable { }
