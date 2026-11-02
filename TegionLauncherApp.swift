import SwiftUI

@main
struct TegionLauncherApp: App {
    @State private var library = LibraryStore()
    @State private var appState = AppState()

    var body: some Scene {
        Window("Tegion Launcher", id: "main") {
            RootView()
                .environment(library)
                .environment(appState)
                .frame(minWidth: 820, minHeight: 540)
        }
        .defaultSize(width: 1120, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Game…") { appState.editor = .add }
                    .keyboardShortcut("n")
                Button("Find Game") {
                    appState.path.removeAll()
                    appState.page = .search
                }
                .keyboardShortcut("f")
            }
        }

        Settings {
            SettingsView()
                .environment(library)
        }
    }
}
