//
//  LockScreenView.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/25/26.
//

import SwiftUI

struct LockScreenView: View {
    var authManager: AuthManager

    @State private var noPasscodeSet = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: noPasscodeSet ? "exclamationmark.triangle" : "lock.shield")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            if noPasscodeSet {
                Text("Device passcode required")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("PlainKey needs a device passcode or Face ID/Touch ID enabled to keep your passwords secure. Set one up in Settings, then reopen PlainKey.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .frame(maxWidth: 200)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            } else {
                Text("PlainKey is locked")
                    .font(.title3)
                    .fontWeight(.semibold)

                Button {
                    authManager.authenticate { success, deviceHasNoPasscode in
                        noPasscodeSet = deviceHasNoPasscode
                    }
                } label: {
                    Label("Unlock", systemImage: "faceid")
                        .frame(maxWidth: 200)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            }
        }
        .padding()
        .onAppear {
            authManager.authenticate { success, deviceHasNoPasscode in
                noPasscodeSet = deviceHasNoPasscode
            }
        }
    }
}

#Preview {
    LockScreenView(authManager: AuthManager())
}
