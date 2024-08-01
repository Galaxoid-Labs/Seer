//
//  Box.swift
//  Seer
//
//  Created by Jacob Davis on 8/1/24.
//

import Foundation

final class Box<T: Hashable>: Hashable {
    var value: T

    init(_ value: T) {
        self.value = value
    }
    
    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        return lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

@propertyWrapper
struct Boxed<T: Hashable>: Hashable {
    var wrappedValue: T {
        get { storage.value }
        set { storage.value = newValue }
    }
    
    var projectedValue: Box<T> { storage }
    let storage: Box<T>

    init(wrappedValue: T) {
        storage = Box(wrappedValue)
    }
    
    static func == (lhs: Boxed<T>, rhs: Boxed<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}
