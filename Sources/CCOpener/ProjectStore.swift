import AppKit
import Combine
import Foundation

@MainActor
final class ProjectStore: ObservableObject {
    static let shared = ProjectStore()

    @Published private(set) var configuration: StoredConfiguration
    @Published private(set) var scannedProjects: [Project] = []
    @Published var selectedProjectID: String?
    @Published var searchText = ""
    @Published var launchError: String?

    private let defaults: UserDefaults
    private let configurationKey = "ccopener.configuration.v1"
    private let fileManager: FileManager

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager

        if let data = defaults.data(forKey: configurationKey),
           let decoded = try? JSONDecoder().decode(StoredConfiguration.self, from: data) {
            configuration = decoded
        } else {
            configuration = StoredConfiguration()
        }
    }

    var allProjects: [Project] {
        let manual = configuration.manualProjectPaths.map {
            Project(path: $0, origin: .manual)
        }

        var projectsByPath = Dictionary(uniqueKeysWithValues: scannedProjects.map { ($0.path, $0) })
        for project in manual {
            projectsByPath[project.path] = project
        }

        return projectsByPath.values.sorted { lhs, rhs in
            let lhsFavorite = isFavorite(lhs)
            let rhsFavorite = isFavorite(rhs)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var filteredProjects: [Project] {
        guard !searchText.isEmpty else { return allProjects }
        return allProjects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedProject: Project? {
        guard let selectedProjectID else { return nil }
        return allProjects.first { $0.id == selectedProjectID }
    }

    func isFavorite(_ project: Project) -> Bool {
        configuration.favoritePaths.contains(project.path)
    }

    func toggleFavorite(_ project: Project) {
        if configuration.favoritePaths.contains(project.path) {
            configuration.favoritePaths.remove(project.path)
        } else {
            configuration.favoritePaths.insert(project.path)
        }
        save()
        objectWillChange.send()
    }

    func chooseAndAddProject() {
        guard let path = chooseDirectory(prompt: "Wybierz projekt") else { return }
        addManualProject(path: path)
    }

    func chooseAndAddScanFolder() {
        guard let path = chooseDirectory(prompt: "Wybierz folder zawierający projekty") else { return }
        addScanFolder(path: path)
    }

    func addManualProject(path: String) {
        let path = canonicalPath(path)
        guard !configuration.manualProjectPaths.contains(path) else {
            selectedProjectID = path
            return
        }
        configuration.manualProjectPaths.append(path)
        save()
        selectedProjectID = path
        syncSpotlightIndex()
    }

    func addScanFolder(path: String) {
        let path = canonicalPath(path)
        guard !configuration.scanFolderPaths.contains(path) else { return }
        configuration.scanFolderPaths.append(path)
        save()
        refreshScannedProjects()
    }

    func removeManualProject(_ project: Project) {
        configuration.manualProjectPaths.removeAll { $0 == project.path }
        configuration.favoritePaths.remove(project.path)
        if selectedProjectID == project.id { selectedProjectID = nil }
        save()
        syncSpotlightIndex()
    }

    func removeScanFolder(path: String) {
        configuration.scanFolderPaths.removeAll { $0 == path }
        save()
        refreshScannedProjects()
    }

    func refreshScannedProjects() {
        var discovered: [String: Project] = [:]
        let keys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey]

        for rootPath in configuration.scanFolderPaths {
            let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
            guard let children = try? fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for child in children {
                guard let values = try? child.resourceValues(forKeys: Set(keys)),
                      values.isDirectory == true,
                      values.isHidden != true else { continue }
                let path = canonicalPath(child.path)
                discovered[path] = Project(path: path, origin: .scanned(root: rootPath))
            }
        }

        scannedProjects = discovered.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        syncSpotlightIndex()
    }

    func launch(_ project: Project) {
        do {
            try TerminalLauncher.launchClaude(in: project.path)
            launchError = nil
        } catch {
            launchError = error.localizedDescription
        }
    }

    func launchProject(atPath path: String) {
        let project = allProjects.first { $0.path == path }
            ?? Project(path: path, origin: .manual)
        launch(project)
    }

    private func chooseDirectory(prompt: String) -> String? {
        let panel = NSOpenPanel()
        panel.title = prompt
        panel.prompt = "Wybierz"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }

    private func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path, isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: configurationKey)
    }

    private func syncSpotlightIndex() {
        SpotlightIndexer.replaceProjects(with: allProjects)
    }
}
