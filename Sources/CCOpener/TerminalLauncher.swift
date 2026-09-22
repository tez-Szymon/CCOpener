import Foundation
@preconcurrency import ApplicationServices
import OSLog

enum TerminalLauncher {
    enum LaunchError: LocalizedError {
        case projectDoesNotExist
        case accessibilityRequired
        case appleScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .projectDoesNotExist:
                return "Folder projektu już nie istnieje."
            case .accessibilityRequired:
                return "Aby otwierać nowe karty, włącz CCOpener w Ustawieniach systemowych → Prywatność i ochrona → Dostępność. Jeśli CCOpener jest już włączony, usuń go z listy i dodaj ponownie aplikację z /Applications/CCOpener.app. Po przebudowaniu aplikacji macOS może wymagać ponownego nadania uprawnień."
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
            set launchCommand to "cd " & quoted form of projectPath & " && { update_terminal_cwd 2>/dev/null; claude; }"
            set targetTab to my newTabInExistingWindow()
            tell application "Terminal"
                if targetTab is missing value then
                    do script launchCommand
                    log "Opened a new Terminal window."
                else
                    do script launchCommand in targetTab
                    log "Opened a new Terminal tab."
                end if
                activate
            end tell
        end run

        on newTabInExistingWindow()
            tell application "Terminal"
                if not running then return missing value
                if (count of windows) is 0 then return missing value
            end tell

            try
                tell application "Terminal"
                    set existingTTYs to {}
                    repeat with terminalWindow in windows
                        set existingTTYs to existingTTYs & (tty of every tab of terminalWindow)
                    end repeat
                    set miniaturized of front window to false
                    activate
                end tell

                tell application "System Events"
                    tell process "Terminal"
                        set frontmost to true
                        repeat 40 times
                            if frontmost then exit repeat
                            delay 0.05
                        end repeat
                        if not frontmost then error "Terminal did not become frontmost."
                        keystroke "t" using command down
                    end tell
                end tell

                -- Wait for a new session, never send the command to an existing tab.
                repeat 40 times
                    tell application "Terminal"
                        -- Window ordering and selection can lag behind tab creation.
                        repeat with terminalWindow in windows
                            repeat with candidateTab in tabs of terminalWindow
                                set candidateTTY to tty of candidateTab
                                if candidateTTY is not "" and candidateTTY is not in existingTTYs then
                                    return contents of candidateTab
                                end if
                            end repeat
                        end repeat
                    end tell
                    delay 0.05
                end repeat
            on error errorMessage number errorNumber
                if errorNumber is 1002 or errorNumber is -1719 or errorNumber is -25211 then
                    error "CCOPENER_ACCESSIBILITY_REQUIRED: " & errorMessage number errorNumber
                end if
                -- UI scripting can be denied by macOS; a new window still works.
                log "Terminal tab creation failed (" & errorNumber & "): " & errorMessage
                return missing value
            end try
            log "Terminal tab creation timed out: no new session appeared."
            return missing value
        end newTabInExistingWindow
        """

        let process = Process()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, projectPath]
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "nieznany błąd"
        let logger = Logger(subsystem: "com.ccopener.app", category: "TerminalLauncher")
        logger.notice("Terminal launch: \(message, privacy: .public)")

        guard process.terminationStatus == 0 else {
            if message.contains("CCOPENER_ACCESSIBILITY_REQUIRED") {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
                throw LaunchError.accessibilityRequired
            }
            throw LaunchError.appleScriptFailed(message)
        }
    }
}
