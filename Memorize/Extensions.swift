//
//  Extensions.swift
//  Memorize
//
//  Created by Sigrid Mortensen on 9/6/22.
//

import Foundation

extension Bool {
    public var intValue: Int {
        return self ? 1 : 0
    }
}

extension Int {
    public var boolValue: Bool {
        return self != 0
    }
}

extension Array where Element: Any {
    public func noneSatisfy(_ test: (Element)-> Bool) -> Bool {
        for x in self {
            if test(x) {
                return false // at least one satisfies the test
            }
        }
        return true // got all the way through and none satisfied the test
    }
    
    public func anySatisfy(_ test: (Element)-> Bool) -> Bool {
        for x in self {
            if test(x) {
                return true // at least one satisfies the test
            }
        }
        return false // got all the way through and none satisfied the test
    }
}
