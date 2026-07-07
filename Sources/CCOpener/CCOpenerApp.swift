import SwiftUI

@main
struct CCOpenerApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        MenuBarExtra("CCOpener", systemImage: "terminal.fill") {
            MenuBarView()
                .environmentObject(store)
                .onAppear { store.refreshScannedProjects() }
        }
        .menuBarExtraStyle(.window)
    }
}
