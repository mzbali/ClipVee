import SwiftUI
import Defaults

struct PrivacySettingsPane: View {
  private enum IgnoreList: String, CaseIterable, Identifiable {
    case apps = "Apps"
    case types = "Clipboard types"
    case patterns = "Patterns"

    var id: Self { self }
  }

  @Default(.ignoreEvents) private var ignoreEvents
  @State private var ignoreList: IgnoreList = .apps

  var body: some View {
    SettingsPageView(title: "Privacy") {
      SettingsCard(
        icon: "pause.circle",
        title: "Pause clipboard history",
        description: "New copies aren't saved while paused. Option-click the menu bar icon to pause, or Option-Shift-click to skip only the next copy."
      ) {
        Toggle("Pause clipboard history", isOn: Binding(
          get: { ignoreEvents },
          set: { Clipboard.shared.setHistoryPaused($0) }
        ))
      }

      Text("ClipVee skips content marked sensitive or temporary by supported apps. Passwords and secrets copied as ordinary text can still be saved. Pause history or ignore the source app when needed.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 4)
        .padding(.top, 6)

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
    }
  }
}

#Preview {
  PrivacySettingsPane()
}
