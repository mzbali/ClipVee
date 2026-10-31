import SwiftUI
import Defaults
import LaunchAtLogin

struct GeneralSettingsPane: View {
  private let notificationsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(Bundle.main.bundleIdentifier ?? "")"
  )

  @Default(.searchMode) private var searchMode

  @State private var updater = SoftwareUpdater.shared

  var body: some View {
    SettingsPageView(title: "General") {
      SettingsCard(icon: "power", title: "Launch at login") {
        LaunchAtLogin.Toggle { Text("Launch at login") }
      }
      if SoftwareUpdater.isAvailable {
        SettingsCard(icon: "arrow.down.circle", title: "Check for updates automatically") {
          HStack {
            Button("Check now") { updater.checkForUpdates() }
            Toggle("Check for updates automatically", isOn: $updater.automaticallyChecksForUpdates)
          }
        }
      }

      SettingsSectionHeader("Pasting")
      SettingsCard(
        icon: "doc.on.clipboard",
        title: "Paste automatically",
        description: "Return or a click pastes into the app you were using. When off, it only copies."
      ) {
        Defaults.Toggle("Paste automatically", key: .pasteByDefault)
      }
      SettingsCard(
        icon: "textformat",
        title: "Paste as plain text",
        description: "Remove fonts, colours and links when pasting."
      ) {
        Defaults.Toggle("Paste as plain text", key: .removeFormattingByDefault)
      }

      SettingsSectionHeader("Search")
      SettingsCard(
        icon: "magnifyingglass",
        title: "Matching",
        description: "How typing in the panel finds items."
      ) {
        Picker("Matching", selection: $searchMode) {
          ForEach(Search.Mode.allCases) { mode in
            Text(mode.description)
          }
        }
        .fixedSize()
      }

      if let notificationsURL {
        SettingsSectionHeader("Notifications")
        SettingsCard(
          icon: "bell",
          title: "Notifications and sounds",
          description: "Managed in System Settings."
        ) {
          Link("Open", destination: notificationsURL)
        }
      }
    }
  }
}

#Preview {
  GeneralSettingsPane()
}
