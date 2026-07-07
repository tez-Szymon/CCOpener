import Foundation

struct Project: Identifiable, Hashable {
    enum Origin: Hashable {
        case manual
        case scanned(root: String)
    }

    let path: String
    let origin: Origin

    var id: String { path }
    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

struct StoredConfiguration: Codable, Equatable {
    var manualProjectPaths: [String] = []
    var scanFolderPaths: [String] = []
    var favoritePaths: Set<String> = []
}
