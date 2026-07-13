import AppKit
import CoreSpotlight
import SwiftUI

@main
struct CCOpenerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ProjectStore.shared

    var body: some Scene {
        MenuBarExtra("CCOpener", systemImage: "terminal.fill") {
            MenuBarView()
                .environmentObject(store)
                .onAppear { store.refreshScannedProjects() }
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ProjectStore.shared.refreshScannedProjects()
    }

    func application(
        _ application: NSApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void
    ) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let path = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        ProjectStore.shared.launchProject(atPath: path)
        return true
    }
}
