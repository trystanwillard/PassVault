//
//  PasswordGenerator.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/27/26.
//

import Foundation

enum PasswordGenerator {
    static func generate(
        length: Int = 16,
        includeUppercase: Bool = true,
        includeNumbers: Bool = true,
        includeSymbols: Bool = true
    ) -> String {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()-_=+[]{}"
        
        var pool = lowercase
        var required: [Character] = [lowercase.randomElement()!]
        
        if includeUppercase {
            pool += uppercase
            required.append(uppercase.randomElement()!)
        }
        if includeNumbers {
            pool += numbers
            required.append(numbers.randomElement()!)
        }
        if includeSymbols {
            pool += symbols
            required.append(symbols.randomElement()!)
        }
        
        let remainingLength = max(length - required.count, 0)
        let randomChars = (0..<remainingLength).map { _ in pool.randomElement()! }
        
        
        var result = required + randomChars
        result.shuffle()
        
        return String(result)
    }
}
