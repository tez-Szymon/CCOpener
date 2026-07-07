import XCTest
@testable import CCOpener

@MainActor
final class ProjectStoreTests: XCTestCase {
    func testManualProjectsAreDeduplicated() {
        let store = ProjectStore(defaults: freshDefaults())
        store.addManualProject(path: "/tmp/sample")
        store.addManualProject(path: "/tmp/sample")

        XCTAssertEqual(store.configuration.manualProjectPaths.count, 1)
    }

    func testFavoriteProjectIsSortedFirst() {
        let store = ProjectStore(defaults: freshDefaults())
        store.addManualProject(path: "/tmp/alpha")
        store.addManualProject(path: "/tmp/zulu")
        let zulu = store.allProjects.first { $0.name == "zulu" }!

        store.toggleFavorite(zulu)

        XCTAssertEqual(store.allProjects.first?.name, "zulu")
    }

    func testConfigurationPersists() {
        let defaults = freshDefaults()
        let firstStore = ProjectStore(defaults: defaults)
        firstStore.addManualProject(path: "/tmp/persisted")

        let secondStore = ProjectStore(defaults: defaults)

        XCTAssertEqual(secondStore.configuration.manualProjectPaths, ["/tmp/persisted"])
    }

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ProjectStoreTests.\(UUID().uuidString)")!
    }
}
