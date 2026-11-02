import SwiftUI

struct SettingsView: View {
    @Environment(LibraryStore.self) private var library
    @AppStorage("igdbClientID") private var clientID = ""
    @AppStorage("igdbClientSecret") private var clientSecret = ""

    var body: some View {
        @Bindable var library = library

        Form {
            Section {
                TextField("Client ID", text: $clientID)
                SecureField("Client Secret", text: $clientSecret)
            } header: {
                Text("IGDB")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Game search and artwork come from IGDB. Register a free application in the Twitch Developer Console (your Twitch account needs two-factor authentication), then paste its Client ID and Secret here.")
                    Link("Open Twitch Developer Console",
                         destination: URL(string: "https://dev.twitch.tv/console/apps")!)
                }
            }

            Section {
                TextField("Drive name", text: $library.ssdName)
            } header: {
                Text("External Drive")
            } footer: {
                Text("The name of your external drive as it appears in Finder. Tegion uses it to label games and to tell you when the drive isn't connected.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 420)
        .onChange(of: library.ssdName) {
            library.saveSettings()
        }
    }
}
