import SwiftUI
import Defaults
import KeyboardShortcuts

struct ShortcutsSettingsPane: View {
  @Default(.pasteByDefault) private var pasteByDefault
  @Default(.removeFormattingByDefault) private var removeFormattingByDefault

  var body: some View {
    SettingsPageView(title: "Shortcuts") {
      SettingsCard(
        icon: "rectangle.stack",
        title: "Open the panel",
        description: "Works in any app. Press it again to close."
      ) {
        KeyboardShortcuts.Recorder(for: .popup) { newShortcut in
          if newShortcut == nil {
            // No shortcut is recorded. Remove keys monitor
            AppState.shared.popup.deinitEventsMonitor()
          } else {
            // User is using shortcut. Ensure keys monitor is initialized
            AppState.shared.popup.initEventsMonitor()
          }
        }
      }

      SettingsSectionHeader("In the panel")
      SettingsCard(icon: "pin", title: "Pin or unpin") {
        KeyboardShortcuts.Recorder(for: .pin)
      }
      SettingsCard(icon: "trash", title: "Delete") {
        KeyboardShortcuts.Recorder(for: .delete)
      }
      SettingsCard(icon: "sidebar.right", title: "Show details") {
        KeyboardShortcuts.Recorder(for: .togglePreview)
      }

      SettingsSectionHeader("Choosing an item")
      VStack(alignment: .leading, spacing: 6) {
        modifierRow("Return or click", action: title(for: defaultAction))
        ForEach([HistoryItemAction.copy, .paste, .pasteWithoutFormatting], id: \.self) { action in
          if action != defaultAction {
            modifierRow("\(action.modifierFlags.description) Return or click", action: title(for: action))
          }
        }
        modifierRow("⌘1 – ⌘9", action: "Choose one of the nine newest items")
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .settingsCardBackground()
    }
  }

  private var defaultAction: HistoryItemAction {
    guard pasteByDefault else { return .copy }
    return removeFormattingByDefault ? .pasteWithoutFormatting : .paste
  }

  private func title(for action: HistoryItemAction) -> LocalizedStringKey {
    switch action {
    case .copy: "Copy only"
    case .pasteWithoutFormatting: "Paste as plain text"
    default: "Paste"
    }
  }

  private func modifierRow(_ keys: String, action: LocalizedStringKey) -> some View {
    HStack {
      Text(verbatim: keys)
        .font(.system(size: 12).monospaced())
        .frame(width: 170, alignment: .leading)
      Text(action)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  ShortcutsSettingsPane()
}
