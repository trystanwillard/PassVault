//
//  AuthManager.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/25/26.
//
import Foundation
import LocalAuthentication

@Observable
final class AuthManager {
    var isUnlocked = false

    private var idleTimer: Timer?
    private var lastActivity = Date()
    private let idleTimeout: TimeInterval = 60

    func authenticate(completion: @escaping (Bool, Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = false
            let noPasscode = (error as? LAError)?.code == .passcodeNotSet
            completion(false, noPasscode)
            return
        }

        let reason = "Unlock PlainKey to view your passwords"

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                self.isUnlocked = success
                if success {
                    self.startIdleTimer()
                }
                completion(success, false)
            }
        }
    }

    func lock() {
        isUnlocked = false
        stopIdleTimer()
    }

    func recordActivity() {
        lastActivity = Date()
    }

    private func startIdleTimer() {
        lastActivity = Date()
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if Date().timeIntervalSince(self.lastActivity) > self.idleTimeout {
                self.lock()
            }
        }
    }

    private func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }
}
