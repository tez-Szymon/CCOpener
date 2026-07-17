import Foundation

enum CCOpenerURL {
    static let scheme = "ccopener"

    static func projectPath(from url: URL) -> String? {
        guard url.scheme?.lowercased() == scheme,
              url.host?.lowercased() == "launch",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.queryItems?.first(where: { $0.name == "path" })?.value,
              path.hasPrefix("/") else {
            return nil
        }

        return path
    }
}
