import Foundation

enum TerminalLauncher {
    enum LaunchError: LocalizedError {
        case projectDoesNotExist
        case appleScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .projectDoesNotExist:
                return "Folder projektu już nie istnieje."
            case .appleScriptFailed(let message):
                return "Nie udało się otworzyć Terminala: \(message)"
            }
        }
    }

    static func launchClaude(in projectPath: String) throws {
        guard FileManager.default.fileExists(atPath: projectPath) else {
            throw LaunchError.projectDoesNotExist
        }

        let script = """
        on run argv
            set projectPath to item 1 of argv
            tell application "Terminal"
                activate
                do script "cd " & quoted form of projectPath & " && claude"
            end tell
        end run
        """

        let process = Process()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, projectPath]
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw LaunchError.appleScriptFailed(message ?? "nieznany błąd")
        }
    }
}
