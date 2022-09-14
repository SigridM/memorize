//
//  Extensions.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/6/22.
//

import Foundation

extension Bool {
    /// Turns a Boolean into an integer: 1 if the receiver is true, and 0 if false
    public var intValue: Int {
        return self ? 1 : 0
    }
}

extension Int {
    /// Turns an integer into a Boolean, false only if the receiver is zero
    public var boolValue: Bool {
        return self != 0
    }
}

extension Array where Element: Any {
    /// Looks through the array to ascertain if no elements pass the given test
    /// - Parameter test: a closure taking one element and returning a Boolean: true if that element passes the test
    /// - Returns: a Boolean: true if no elements pass the test (i.e., if all elements fail the test); false if even one element passes
    public func noneSatisfy(_ test: (Element)-> Bool) -> Bool {
        for x in self {
            if test(x) {
                return false // at least one satisfies the test
            }
        }
        return true // got all the way through and none satisfied the test
    }
    
    /// Looks through the array to ascertain whether at least one element passes the given test
    /// - Parameter test: a closure taking one element and returning a Boolean: true if that element passes the test
    /// - Returns: a Boolean: true if at least one element passes the test; false if all elements fail the test.
    public func anySatisfy(_ test: (Element)-> Bool) -> Bool {
        for x in self {
            if test(x) {
                return true // at least one satisfies the test
            }
        }
        return false // got all the way through and none satisfied the test
    }
}
