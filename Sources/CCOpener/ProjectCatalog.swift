import Foundation

struct ProjectCatalog: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let projects: [CatalogProject]

    init(projects: [CatalogProject]) {
        schemaVersion = Self.currentSchemaVersion
        self.projects = projects
    }

    static func defaultURL(fileManager: FileManager = .default) -> URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("CCOpener", isDirectory: true)
            .appendingPathComponent("projects.json", isDirectory: false)
    }
}

struct CatalogProject: Codable, Equatable {
    let name: String
    let path: String
    let isFavorite: Bool
}

enum ProjectCatalogWriter {
    static func write(
        projects: [Project],
        favoritePaths: Set<String>,
        to url: URL,
        fileManager: FileManager = .default
    ) throws {
        let catalog = ProjectCatalog(projects: projects.map {
            CatalogProject(
                name: $0.name,
                path: $0.path,
                isFavorite: favoritePaths.contains($0.path)
            )
        })

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(catalog)

        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }
}
