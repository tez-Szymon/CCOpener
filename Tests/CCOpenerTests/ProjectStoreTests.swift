import XCTest
@testable import CCOpener

@MainActor
final class ProjectStoreTests: XCTestCase {
    func testManualProjectsAreDeduplicated() {
        let store = makeStore()
        store.addManualProject(path: "/tmp/sample")
        store.addManualProject(path: "/tmp/sample")

        XCTAssertEqual(store.configuration.manualProjectPaths.count, 1)
    }

    func testFavoriteProjectIsSortedFirst() {
        let store = makeStore()
        store.addManualProject(path: "/tmp/alpha")
        store.addManualProject(path: "/tmp/zulu")
        let zulu = store.allProjects.first { $0.name == "zulu" }!

        store.toggleFavorite(zulu)

        XCTAssertEqual(store.allProjects.first?.name, "zulu")
    }

    func testConfigurationPersists() {
        let defaults = freshDefaults()
        let firstStore = ProjectStore(defaults: defaults, catalogURL: nil)
        firstStore.addManualProject(path: "/tmp/persisted")

        let secondStore = ProjectStore(defaults: defaults, catalogURL: nil)

        XCTAssertEqual(secondStore.configuration.manualProjectPaths, ["/tmp/persisted"])
    }

    func testProjectCatalogContainsFavorites() throws {
        let catalogURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("projects.json")
        defer { try? FileManager.default.removeItem(at: catalogURL.deletingLastPathComponent()) }

        let store = ProjectStore(defaults: freshDefaults(), catalogURL: catalogURL)
        store.addManualProject(path: "/tmp/zulu")
        let project = try XCTUnwrap(store.allProjects.first)
        store.toggleFavorite(project)

        let data = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(ProjectCatalog.self, from: data)

        XCTAssertEqual(catalog.schemaVersion, ProjectCatalog.currentSchemaVersion)
        XCTAssertEqual(
            catalog.projects,
            [CatalogProject(name: "zulu", path: "/tmp/zulu", isFavorite: true)]
        )
    }

    func testCCOpenerURLExtractsAnEncodedProjectPath() throws {
        let url = try XCTUnwrap(URL(string: "ccopener://launch?path=%2Ftmp%2Fproject%20name"))

        XCTAssertEqual(CCOpenerURL.projectPath(from: url), "/tmp/project name")
    }

    func testCCOpenerURLRejectsOtherSchemes() throws {
        let url = try XCTUnwrap(URL(string: "https://launch?path=%2Ftmp%2Fproject"))

        XCTAssertNil(CCOpenerURL.projectPath(from: url))
    }

    private func makeStore() -> ProjectStore {
        ProjectStore(defaults: freshDefaults(), catalogURL: nil)
    }

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ProjectStoreTests.\(UUID().uuidString)")!
    }
}
