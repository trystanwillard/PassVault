//
//  PassVaultApp.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/23/26.
//

import SwiftUI

@main
struct PassVaultApp: App {
    @State private var authManager = AuthManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isUnlocked {
                    ContentView(authManager: authManager)
                } else {
                    LockScreenView(authManager: authManager)
                }
            }
            
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    authManager.lock()
                }
            }
            
        }
    }
}
