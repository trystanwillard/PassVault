//
//  EditEntryView.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/27/26.
//
import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss

    var authManager: AuthManager
    let originalEntry: PasswordEntry

    @State private var site: String
    @State private var username: String
    @State private var password: String
    @State private var isPasswordVisible: Bool = false
    @State private var passwordLength: Double = 16
    @State private var loadError: String?

    var onSave: (PasswordEntry, String) -> Void

    init(entry: PasswordEntry, authManager: AuthManager, onSave: @escaping (PasswordEntry, String) -> Void) {
        self.originalEntry = entry
        self.authManager = authManager
        self.onSave = onSave
        _site = State(initialValue: entry.site)
        _username = State(initialValue: entry.username)
        _password = State(initialValue: "")
    }

    private var isFormValid: Bool {
        !site.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Site") {
                    TextField("e.g. github.com", text: $site)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }

                Section("Login") {
                    TextField("Username or email", text: $username)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.oneTimeCode)

                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .textContentType(.oneTimeCode)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.oneTimeCode)
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        authManager.recordActivity()
                        password = PasswordGenerator.generate(length: Int(passwordLength))
                        isPasswordVisible = true
                    } label: {
                        Label("Generate Strong Password", systemImage: "wand.and.stars")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .padding(.vertical, 10)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 10))
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)

                    VStack(alignment: .leading) {
                        Text("Length: \(Int(passwordLength))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Slider(value: $passwordLength, in: 8...32, step: 1)
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
                ToolbarItem(placement: .principal) {
                    Text("Edit entry")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.recordActivity()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        authManager.recordActivity()
                        let updatedEntry = PasswordEntry(id: originalEntry.id, site: site, username: username)
                        onSave(updatedEntry, password)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadExistingPassword()
            }
        }
    }

    private func loadExistingPassword() {
        do {
            password = try KeychainManager.shared.readPassword(for: originalEntry.id)
        } catch {
            loadError = "Couldn't load existing password."
        }
    }
}

#Preview {
    EditEntryView(
        entry: PasswordEntry(site: "github.com", username: "devuser"),
        authManager: AuthManager(),
        onSave: { _, _ in }
    )
}
