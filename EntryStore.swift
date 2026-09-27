//
//  EntryStore.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/25/26.
//

import Foundation

enum EntryStore {
    private static let key = "passvault.entries"
    
    static func save(_ entries: [PasswordEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func load() -> [PasswordEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([PasswordEntry].self, from: data) else {
            return[]
        }
        return entries
    }
}
