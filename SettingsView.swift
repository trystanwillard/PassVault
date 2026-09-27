//
//  SettingsView.swift
//  PlainKey
//
//  Created by Trystan Willard on 8/1/26.
//
import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    static var writableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = fileData
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var authManager: AuthManager
    var entries: [PasswordEntry]
    var onImport: ([BackupEntry]) -> Void

    @State private var exportPassword = ""
    @State private var importPassword = ""
    @State private var showingExportPasswordPrompt = false
    @State private var showingImportPasswordPrompt = false
    @State private var showingFileExporter = false
    @State private var showingFileImporter = false
    @State private var exportDocument: BackupDocument?
    @State private var pendingImportData: Data?
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        authManager.recordActivity()
                        exportPassword = ""
                        showingExportPasswordPrompt = true
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                } footer: {
                    Text("Creates an encrypted backup file of all your entries, protected by a password you choose. Save it somewhere safe, like Files or iCloud Drive.")
                }

                Section {
                    Button {
                        authManager.recordActivity()
                        showingFileImporter = true
                    } label: {
                        Label("Import Backup", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Restore entries from a previously exported PlainKey backup file.")
                }
            }
            .tint(.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        authManager.recordActivity()
                        dismiss()
                    }
                }
            }
            .alert("Set Export Password", isPresented: $showingExportPasswordPrompt) {
                SecureField("Export password", text: $exportPassword)
                Button("Cancel", role: .cancel) { }
                Button("Export") { performExport() }
            } message: {
                Text("Choose a password to protect this backup. You'll need it again to restore, so don't lose it.")
            }
            .alert("Enter Backup Password", isPresented: $showingImportPasswordPrompt) {
                SecureField("Backup password", text: $importPassword)
                Button("Cancel", role: .cancel) { pendingImportData = nil }
                Button("Import") { performImport() }
            } message: {
                Text("Enter the password used to protect this backup file.")
            }
            .fileExporter(
                isPresented: $showingFileExporter,
                document: exportDocument,
                contentType: .data,
                defaultFilename: "PlainKey-Backup"
            ) { result in
                switch result {
                case .success:
                    successMessage = "Backup exported successfully."
                case .failure:
                    errorMessage = "Couldn't save the backup file."
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.data]
            ) { result in
                switch result {
                case .success(let url):
                    handleFileSelected(url)
                case .failure:
                    errorMessage = "Couldn't read that file."
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { message in
                Text(message)
            }
            .alert("Success", isPresented: .constant(successMessage != nil), presenting: successMessage) { _ in
                Button("OK") { successMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    private func performExport() {
        do {
            let data = try BackupManager.createBackup(entries: entries, exportPassword: exportPassword)
            exportDocument = BackupDocument(data: data)
            showingFileExporter = true
        } catch {
            errorMessage = "Couldn't create the backup. Make sure you have entries saved."
        }
    }

    private func handleFileSelected(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Couldn't access that file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            pendingImportData = try Data(contentsOf: url)
            importPassword = ""
            showingImportPasswordPrompt = true
        } catch {
            errorMessage = "Couldn't read that file."
        }
    }

    private func performImport() {
        guard let data = pendingImportData else { return }
        do {
            let restored = try BackupManager.restoreBackup(data: data, exportPassword: importPassword)
            onImport(restored)
            successMessage = "Imported \(restored.count) entr\(restored.count == 1 ? "y" : "ies")."
            pendingImportData = nil
        } catch {
            errorMessage = "Incorrect password, or this file isn't a valid backup."
            pendingImportData = nil
        }
    }
}

#Preview {
    SettingsView(authManager: AuthManager(), entries: [], onImport: { _ in })
}
