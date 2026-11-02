import SwiftUI
import Defaults

struct HistorySettingsPane: View {
  @Default(.enabledPasteboardTypes) private var enabledPasteboardTypes
  @Default(.size) private var size
  @Default(.sortBy) private var sortBy

  @State private var storageSize = Storage.shared.size

  private let sizeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimum = 1
    formatter.maximum = 999
    return formatter
  }()

  var body: some View {
    SettingsPageView(title: "History") {
      SettingsSectionHeader("Keep")
      SettingsCard(icon: "doc.plaintext", title: "Text") {
        Toggle("Text", isOn: captureBinding(for: .text))
          .accessibilityIdentifier("capture-text")
      }
      SettingsCard(icon: "photo", title: "Images", description: "Including screenshots copied to the clipboard.") {
        Toggle("Images", isOn: captureBinding(for: .images))
          .accessibilityIdentifier("capture-images")
      }
      SettingsCard(icon: "folder", title: "Files", description: "Files copied in Finder.") {
        Toggle("Files", isOn: captureBinding(for: .files))
          .accessibilityIdentifier("capture-files")
      }

      SettingsSectionHeader("Size")
      SettingsCard(
        icon: "number",
        title: "Items to keep",
        description: "Pinned items don't count. Using \(storageSize) on disk."
      ) {
        HStack(spacing: 4) {
          TextField("Items to keep", value: $size, formatter: sizeFormatter)
            .frame(width: 50)
            .multilineTextAlignment(.trailing)
          Stepper("Items to keep", value: $size, in: 1...999)
        }
      }
      SettingsCard(icon: "arrow.up.arrow.down", title: "Sort by") {
        Picker("Sort by", selection: $sortBy) {
          ForEach(Sorter.By.allCases) { mode in
            Text(mode.description)
          }
        }
        .fixedSize()
      }

      SettingsSectionHeader("Clearing")
      SettingsCard(
        icon: "trash",
        title: "Clear history on quit",
        description: "Remove all unpinned items when ClipVee quits."
      ) {
        Defaults.Toggle("Clear history on quit", key: .clearOnQuit)
      }
      SettingsCard(
        icon: "clipboard",
        title: "Clear the system clipboard too",
        description: "Clearing history also empties what Command-V would paste."
      ) {
        Defaults.Toggle("Clear the system clipboard too", key: .clearSystemClipboard)
      }
    }
    .onAppear { storageSize = Storage.shared.size }
  }

  private func captureBinding(for type: StorageType) -> Binding<Bool> {
    Binding(
      get: { enabledPasteboardTypes.isSuperset(of: type.types) },
      set: { enabled in
        var types = enabledPasteboardTypes
        if enabled {
          types.formUnion(type.types)
        } else {
          types.subtract(type.types)
        }
        enabledPasteboardTypes = types
      }
    )
  }

}

#Preview {
  HistorySettingsPane()
}
