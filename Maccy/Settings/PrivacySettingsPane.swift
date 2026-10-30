import SwiftUI
import Defaults

struct PrivacySettingsPane: View {
  private enum IgnoreList: String, CaseIterable, Identifiable {
    case apps = "Apps"
    case types = "Clipboard types"
    case patterns = "Patterns"

    var id: Self { self }
  }

  @State private var ignoreList: IgnoreList = .apps
  @State private var showsScript = false

  private var bundleIdentifier: String { Bundle.main.bundleIdentifier ?? "" }

  var body: some View {
    SettingsPageView(title: "Privacy") {
      SettingsCard(
        icon: "pause.circle",
        title: "Pause clipboard history",
        description: "New copies aren't saved while paused. Option-click the menu bar icon to pause, or Option-Shift-click to skip only the next copy."
      ) {
        Defaults.Toggle("Pause clipboard history", key: .ignoreEvents)
      }

      SettingsSectionHeader("Ignore copies from")
      VStack(spacing: 0) {
        Picker("Ignore copies from", selection: $ignoreList) {
          ForEach(IgnoreList.allCases) { list in
            Text(LocalizedStringKey(list.rawValue)).tag(list)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding([.horizontal, .top], 12)

        Group {
          switch ignoreList {
          case .apps: IgnoreApplicationsSettingsView()
          case .types: IgnorePasteboardTypesSettingsView()
          case .patterns: IgnoreRegexpsSettingsView()
          }
        }
        .frame(height: 280)
      }
      .settingsCardBackground()

      DisclosureGroup("Pause from a script", isExpanded: $showsScript) {
        Text(verbatim: """
          defaults write \(bundleIdentifier) ignoreEvents true
          # copy sensitive data
          defaults write \(bundleIdentifier) ignoreEvents false

          # or skip only the next copy
          defaults write \(bundleIdentifier) ignoreOnlyNextEvent true
          """)
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
      }
      .padding(.top, 12)
    }
  }
}

#Preview {
  PrivacySettingsPane()
}
