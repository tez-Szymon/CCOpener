import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var showingFolders = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            search
            projectList
            Divider()
            footer
        }
        .frame(width: 410, height: 520)
        .sheet(isPresented: $showingFolders) {
            ScanFoldersView()
                .environmentObject(store)
        }
        .alert("Nie udało się uruchomić Claude Code", isPresented: Binding(
            get: { store.launchError != nil },
            set: { if !$0 { store.launchError = nil } }
        )) {
            Button("OK", role: .cancel) { store.launchError = nil }
        } message: {
            Text(store.launchError ?? "Nieznany błąd")
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "terminal.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("CCOpener")
                .font(.headline)
            Spacer()

            Button {
                store.refreshScannedProjects()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Odśwież projekty")

            Menu {
                Button("Dodaj projekt…", action: store.chooseAndAddProject)
                Button("Dodaj folder projektów…", action: store.chooseAndAddScanFolder)
                Divider()
                Button("Zarządzaj folderami…") { showingFolders = true }
            } label: {
                Image(systemName: "plus")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Dodaj")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var search: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Szukaj projektów", text: $store.searchText)
                .textFieldStyle(.plain)
            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var projectList: some View {
        if store.filteredProjects.isEmpty {
            ContentUnavailableView(
                store.searchText.isEmpty ? "Brak projektów" : "Brak wyników",
                systemImage: store.searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                description: Text(store.searchText.isEmpty
                    ? "Dodaj projekt przyciskiem +."
                    : "Spróbuj użyć innej nazwy.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(store.filteredProjects) { project in
                        MenuBarProjectRow(project: project)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(store.allProjects.count) projektów")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Zakończ") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct MenuBarProjectRow: View {
    @EnvironmentObject private var store: ProjectStore
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.launch(project)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(project.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.toggleFavorite(project)
            } label: {
                Image(systemName: store.isFavorite(project) ? "star.fill" : "star")
                    .foregroundStyle(store.isFavorite(project) ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(store.isFavorite(project) ? "Usuń z ulubionych" : "Dodaj do ulubionych")

            Button {
                store.launch(project)
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)
            .help("Uruchom Claude Code")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.001), in: RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button("Uruchom Claude Code") { store.launch(project) }
            Button(store.isFavorite(project) ? "Usuń z ulubionych" : "Dodaj do ulubionych") {
                store.toggleFavorite(project)
            }
            if project.origin == .manual {
                Divider()
                Button("Usuń z listy", role: .destructive) {
                    store.removeManualProject(project)
                }
            }
        }
    }
}
