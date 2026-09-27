//
//  AddEntryView.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/23/26.
//


import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss

    var authManager: AuthManager

    @State private var site: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var passwordLength: Double = 16

    var onSave: (PasswordEntry, String) -> Void

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
            }
            .tint(.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add entry")
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
                        let newEntry = PasswordEntry(site: site, username: username)
                        onSave(newEntry, password)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

#Preview {
    AddEntryView(authManager: AuthManager(), onSave: { _, _ in })
}
