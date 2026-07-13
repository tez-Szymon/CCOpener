@preconcurrency import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

enum SpotlightIndexer {
    private static let domainIdentifier = "com.ccopener.projects"

    static func replaceProjects(with projects: [Project]) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let items = projects.map(makeSearchableItem)
        let index = CSSearchableIndex.default()

        index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            guard error == nil, !items.isEmpty else { return }
            index.indexSearchableItems(items, completionHandler: nil)
        }
    }

    private static func makeSearchableItem(for project: Project) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .folder)
        attributes.title = project.name
        attributes.displayName = project.name
        attributes.contentDescription = "Uruchom Claude Code w projekcie \(project.name)"
        attributes.path = project.path
        attributes.keywords = [
            "CCOpener",
            "Claude Code",
            "projekt",
            project.name,
            project.path
        ]

        return CSSearchableItem(
            uniqueIdentifier: project.path,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }
}
