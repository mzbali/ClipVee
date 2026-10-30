import SwiftUI
import Defaults

struct HistorySettingsPane: View {
  @Observable
  class ViewModel {
    var saveFiles = false {
      didSet {
        Defaults.withoutPropagation {
          if saveFiles {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.files.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.files.types)
          }
        }
      }
    }

    var saveImages = false {
      didSet {
        Defaults.withoutPropagation {
          if saveImages {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.images.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.images.types)
          }
        }
      }
    }

    var saveText = false {
      didSet {
        Defaults.withoutPropagation {
          if saveText {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.text.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.text.types)
          }
        }
      }
    }

    private var observer: Defaults.Observation?

    init() {
      observer = Defaults.observe(.enabledPasteboardTypes) { change in
        self.saveFiles = change.newValue.isSuperset(of: StorageType.files.types)
        self.saveImages = change.newValue.isSuperset(of: StorageType.images.types)
        self.saveText = change.newValue.isSuperset(of: StorageType.text.types)
      }
    }

    isolated deinit {
      observer?.invalidate()
    }
  }

  @Default(.size) private var size
  @Default(.sortBy) private var sortBy

  @State private var viewModel = ViewModel()
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
        Toggle("Text", isOn: $viewModel.saveText)
      }
      SettingsCard(icon: "photo", title: "Images", description: "Including screenshots copied to the clipboard.") {
        Toggle("Images", isOn: $viewModel.saveImages)
      }
      SettingsCard(icon: "folder", title: "Files", description: "Files copied in Finder.") {
        Toggle("Files", isOn: $viewModel.saveFiles)
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
        description: "Clear all also empties what Command-V would paste."
      ) {
        Defaults.Toggle("Clear the system clipboard too", key: .clearSystemClipboard)
      }
    }
    .onAppear { storageSize = Storage.shared.size }
  }
}

#Preview {
  HistorySettingsPane()
}
