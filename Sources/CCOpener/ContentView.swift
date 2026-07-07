import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var showingFolders = false

    var body: some View {
        NavigationSplitView {
            projectList
                .navigationSplitViewColumnWidth(min: 310, ideal: 370)
        } detail: {
            detail
        }
        .searchable(text: $store.searchText, placement: .sidebar, prompt: "Szukaj projektów")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.refreshScannedProjects()
                } label: {
                    Label("Odśwież", systemImage: "arrow.clockwise")
                }
                .help("Odśwież projekty z obserwowanych folderów")

                Menu {
                    Button("Dodaj projekt…", action: store.chooseAndAddProject)
                    Button("Dodaj folder projektów…", action: store.chooseAndAddScanFolder)
                    Divider()
                    Button("Zarządzaj folderami…") { showingFolders = true }
                } label: {
                    Label("Dodaj", systemImage: "plus")
                }
            }
        }
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

    private var projectList: some View {
        List(selection: $store.selectedProjectID) {
            if store.filteredProjects.isEmpty {
                ContentUnavailableView(
                    store.searchText.isEmpty ? "Brak projektów" : "Brak wyników",
                    systemImage: store.searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass",
                    description: Text(store.searchText.isEmpty
                        ? "Dodaj projekt lub folder zawierający projekty."
                        : "Spróbuj użyć innej nazwy albo ścieżki.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(store.filteredProjects) { project in
                    ProjectRow(project: project)
                        .tag(project.id)
                        .contextMenu {
                            Button(store.isFavorite(project) ? "Usuń z ulubionych" : "Dodaj do ulubionych") {
                                store.toggleFavorite(project)
                            }
                            Button("Uruchom Claude Code") { store.launch(project) }
                            if project.origin == .manual {
                                Divider()
                                Button("Usuń z listy", role: .destructive) {
                                    store.removeManualProject(project)
                                }
                            }
                        }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if !store.allProjects.isEmpty {
                Text("\(store.allProjects.count) \(projectCountLabel(store.allProjects.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let project = store.selectedProject {
            VStack(spacing: 20) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.tint)

                VStack(spacing: 6) {
                    Text(project.name)
                        .font(.title.bold())
                    Text(project.path)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Button {
                        store.toggleFavorite(project)
                    } label: {
                        Label(
                            store.isFavorite(project) ? "Ulubiony" : "Dodaj do ulubionych",
                            systemImage: store.isFavorite(project) ? "star.fill" : "star"
                        )
                    }

                    Button {
                        store.launch(project)
                    } label: {
                        Label("Uruchom Claude Code", systemImage: "terminal")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
            }
            .padding(40)
        } else {
            ContentUnavailableView(
                "Wybierz projekt",
                systemImage: "terminal",
                description: Text("Claude Code otworzy się w nowym oknie Terminala.")
            )
        }
    }

    private func projectCountLabel(_ count: Int) -> String {
        count == 1 ? "projekt" : "projektów"
    }
}

private struct ProjectRow: View {
    @EnvironmentObject private var store: ProjectStore
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.tint)
                .font(.title3)

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

            if store.isFavorite(project) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Ulubiony")
            }

            Button {
                store.launch(project)
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)
            .help("Uruchom Claude Code")
        }
        .padding(.vertical, 5)
    }
}

struct ScanFoldersView: View {
    @EnvironmentObject private var store: ProjectStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Foldery projektów")
                .font(.title2.bold())
            Text("Każdy bezpośredni podfolder zostanie dodany jako projekt.")
                .foregroundStyle(.secondary)

            List {
                ForEach(store.configuration.scanFolderPaths, id: \.self) { path in
                    HStack {
                        Image(systemName: "folder")
                        Text(path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            store.removeScanFolder(path: path)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button("Dodaj folder…", action: store.chooseAndAddScanFolder)
                Spacer()
                Button("Gotowe") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 600, height: 330)
    }
}
