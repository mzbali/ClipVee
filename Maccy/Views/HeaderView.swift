import Defaults
import SwiftUI

struct HeaderView: View {
  @State private var appState = AppState.shared
  @State private var confirmClear = false
  @State private var updater = SoftwareUpdater.shared

  let controller: SlideoutController
  @FocusState.Binding var searchFocused: Bool

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "clipboard")
          .foregroundStyle(.secondary)
        Text("Clipboard")
          .font(.system(size: 14, weight: .semibold))
        Spacer()
        if let version = updater.availableVersion {
          Button {
            appState.popup.close()
            updater.checkForUpdates()
          } label: {
            Image(systemName: "arrow.down.circle.fill")
          }
          .foregroundStyle(Color.accentColor)
          .help("ClipVee \(version) is available")
          .accessibilityLabel("Update to ClipVee \(version)")
        }
        Button("Clear all") { confirmClear = true }
          .font(.system(size: 11))
          .buttonStyle(.borderless)
          .disabled(appState.history.unpinnedItems.isEmpty)
        Button { appState.openPreferences() } label: {
          Image(systemName: "gearshape")
        }
        .help("Settings")
        .accessibilityLabel("Clipboard settings")
        Button { appState.popup.close() } label: {
          Image(systemName: "xmark")
        }
        .help("Close")
        .accessibilityLabel("Close clipboard")
        .accessibilityIdentifier("close-clipboard")
      }
      .buttonStyle(.borderless)
      .font(.system(size: 12))
      .padding(.horizontal, 6)

      ListHeaderView(searchFocused: $searchFocused, searchQuery: $appState.history.searchQuery)
        .opacity(appState.searchVisible ? 1 : 0)
        .accessibilityHidden(!appState.searchVisible)
        .frame(maxHeight: appState.searchVisible ? nil : 0)
    }
    .padding(.horizontal, 12)
    .padding(.top, 14)
    .padding(.bottom, 8)
    .readHeight(appState, into: \.popup.headerHeight)
    .alert("Clear clipboard history?", isPresented: $confirmClear) {
      Button("Cancel", role: .cancel) { }
      Button("Clear", role: .destructive) { appState.history.clear(dismissPopup: false) }
    } message: {
      Text("Pinned items will be kept.")
    }
  }
}
