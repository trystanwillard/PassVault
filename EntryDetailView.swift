//
//  EntryDetailView.swift
//  PlainKey
//

import SwiftUI

struct EntryDetailView: View {
    let entry: PasswordEntry
    var authManager: AuthManager
    var onUpdate: (PasswordEntry, String) -> Void

    @State private var password: String = ""
    @State private var isPasswordVisible = false
    @State private var loadError: String?
    @State private var showCopiedToast = false
    @State private var showingEdit = false
    @State private var currentEntry: PasswordEntry

    init(entry: PasswordEntry, authManager: AuthManager, onUpdate: @escaping (PasswordEntry, String) -> Void) {
        self.entry = entry
        self.authManager = authManager
        self.onUpdate = onUpdate
        _currentEntry = State(initialValue: entry)
    }

    private var initial: String {
        String(currentEntry.site.trimmingCharacters(in: .whitespaces).first ?? "?").uppercased()
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(initial)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(Color(uiColor: .systemBackground))
                            )
                        Text(currentEntry.site)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("Login") {
                HStack {
                    Text(currentEntry.username)
                    Spacer()
                    Button {
                        authManager.recordActivity()
                        UIPasteboard.general.string = currentEntry.username
                        showToast()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }

                HStack {
                    if isPasswordVisible {
                        Text(password)
                    } else {
                        Text(String(repeating: "•", count: max(password.count, 8)))
                    }
                    Spacer()
                    Button {
                        authManager.recordActivity()
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        authManager.recordActivity()
                        UIPasteboard.general.string = password
                        showToast()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }

            if let loadError {
                Text(loadError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .tint(.primary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    authManager.recordActivity()
                    showingEdit = true
                }
            }
        }
        .onAppear {
            authManager.recordActivity()
            loadPassword()
        }
        .sheet(isPresented: $showingEdit) {
            EditEntryView(entry: currentEntry, authManager: authManager) { updatedEntry, newPassword in
                onUpdate(updatedEntry, newPassword)
                currentEntry = updatedEntry
                password = newPassword
            }
        }
        .overlay {
            if showCopiedToast {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    Text("Copied")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(width: 120, height: 100)
                .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
    }

    private func showToast() {
        withAnimation(.easeOut(duration: 0.15)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }

    private func loadPassword() {
        do {
            password = try KeychainManager.shared.readPassword(for: currentEntry.id)
        } catch {
            loadError = "Couldn't load password."
        }
    }
}

#Preview {
    NavigationStack {
        EntryDetailView(
            entry: PasswordEntry(site: "github.com", username: "devuser"),
            authManager: AuthManager(),
            onUpdate: { _, _ in }
        )
    }
}
