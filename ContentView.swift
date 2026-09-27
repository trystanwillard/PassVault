//
//  ContentView.swift
//  PlainKey
//
//  Created by Trystan Willard on 7/23/26.
//
import SwiftUI

struct PasswordEntry: Identifiable, Codable {
    let id: UUID
    var site: String
    var username: String

    init(id: UUID = UUID(), site: String, username: String) {
        self.id = id
        self.site = site
        self.username = username
    }
}

struct EntryRow: View {
    let entry: PasswordEntry

    private var initial: String {
        String(entry.site.trimmingCharacters(in: .whitespaces).first ?? "?").uppercased()
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initial)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: .systemBackground))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.site)
                    .font(.system(size: 16, weight: .medium))
                Text(entry.username)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(uiColor: .separator))
        }
    }
}

struct ContentView: View {
    var authManager: AuthManager

    @State private var entries: [PasswordEntry] = []
    @State private var showingAddEntry = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var errorMessage: String?

    private var filteredEntries: [PasswordEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter {
            $0.site.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyStateView
                } else if filteredEntries.isEmpty {
                    noResultsView
                } else {
                    entryList
                }
            }
            .searchable(text: $searchText, prompt: "Search entries")
            .tint(.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PlainKey")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        authManager.recordActivity()
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authManager.recordActivity()
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(authManager: authManager) { newEntry, password in
                    addEntry(newEntry, password: password)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(authManager: authManager, entries: entries, onImport: importEntries)
            }
            .onAppear {
                entries = EntryStore.load()
                authManager.recordActivity()
            }
            .alert("Something went wrong", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    private var entryList: some View {
        List {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    EntryDetailView(entry: entry, authManager: authManager, onUpdate: updateEntry)
                } label: {
                    EntryRow(entry: entry)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .onDelete(perform: deleteEntry)
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No passwords yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the + button to save your first password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                authManager.recordActivity()
                showingAddEntry = true
            } label: {
                Label("Add Password", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No matches for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func addEntry(_ entry: PasswordEntry, password: String) {
        authManager.recordActivity()
        do {
            try KeychainManager.shared.save(password: password, for: entry.id)
            entries.append(entry)
            EntryStore.save(entries)
        } catch {
            errorMessage = "Couldn't save this password. Please try again."
        }
    }

    func updateEntry(_ updatedEntry: PasswordEntry, password: String) {
        authManager.recordActivity()
        do {
            try KeychainManager.shared.save(password: password, for: updatedEntry.id)
            if let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) {
                entries[index] = updatedEntry
            }
            EntryStore.save(entries)
        } catch {
            errorMessage = "Couldn't save your changes. Please try again."
        }
    }

    func importEntries(_ backupEntries: [BackupEntry]) {
        authManager.recordActivity()
        var importFailed = false

        for backupEntry in backupEntries {
            do {
                try KeychainManager.shared.save(password: backupEntry.password, for: backupEntry.id)
                let entry = PasswordEntry(id: backupEntry.id, site: backupEntry.site, username: backupEntry.username)
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = entry
                } else {
                    entries.append(entry)
                }
            } catch {
                importFailed = true
            }
        }

        EntryStore.save(entries)

        if importFailed {
            errorMessage = "Some entries couldn't be imported."
        }
    }

    func deleteEntry(at offsets: IndexSet) {
        authManager.recordActivity()
        var deleteFailed = false

        for index in offsets {
            let entry = filteredEntries[index]
            if let realIndex = entries.firstIndex(where: { $0.id == entry.id }) {
                do {
                    try KeychainManager.shared.delete(for: entry.id)
                    entries.remove(at: realIndex)
                } catch {
                    deleteFailed = true
                }
            }
        }

        EntryStore.save(entries)

        if deleteFailed {
            errorMessage = "Some entries couldn't be fully removed. Please try again."
        }
    }
}

#Preview {
    ContentView(authManager: AuthManager())
}
