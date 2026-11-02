import Defaults
import SwiftUI

struct HeaderView: View {
  @Default(.ignoreEvents) private var ignoreEvents
  @Default(.ignoreOnlyNextEvent) private var ignoreOnlyNextEvent
  @Default(.enabledPasteboardTypes) private var enabledPasteboardTypes
  @Default(.showSearch) private var showSearch
  @Default(.searchVisibility) private var searchVisibility
  @State private var appState = AppState.shared
  @State private var confirmClear = false
  @State private var updater = SoftwareUpdater.shared

  let controller: SlideoutController
  @FocusState.Binding var searchFocused: Bool

  var body: some View {
    let searchVisible = showSearch && (searchVisibility == .always || !appState.history.searchQuery.isEmpty)
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
          .pointingHandCursor()
          .help("ClipVee \(version) is available")
          .accessibilityLabel("Update to ClipVee \(version)")
        }
        Button { appState.openPreferences() } label: {
          Image(systemName: "gearshape")
        }
        .pointingHandCursor()
        .help("Settings")
        .accessibilityLabel("Clipboard settings")
        .accessibilityIdentifier("clipboard-settings")
        Menu {
          Button {
            Clipboard.shared.setHistoryPaused(!ignoreEvents)
          } label: {
            Label(ignoreEvents ? "Resume Clipboard History" : "Pause Clipboard History",
                  systemImage: ignoreEvents ? "play.circle" : "pause.circle")
          }
          Button { confirmClear = true } label: { Label("Clear History…", systemImage: "trash") }
            .disabled(appState.history.unpinnedItems.isEmpty)
          Divider()
          Button { appState.openAbout() } label: { Label("About ClipVee", systemImage: "info.circle") }
          Divider()
          Button { appState.quit() } label: { Label("Quit ClipVee", systemImage: "power") }
        } label: {
          Image(systemName: "ellipsis")
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .pointingHandCursor()
        .help("More actions")
        .accessibilityLabel("More clipboard actions")
        .accessibilityIdentifier("clipboard-actions")
        Button { appState.popup.close() } label: {
          Image(systemName: "xmark")
        }
        .pointingHandCursor()
        .help("Close")
        .accessibilityLabel("Close clipboard")
        .accessibilityIdentifier("close-clipboard")
      }
      .buttonStyle(.borderless)
      .font(.system(size: 12))
      .padding(.horizontal, 6)

      if ignoreEvents || enabledPasteboardTypes.isEmpty {
        captureStatus
      }

      ListHeaderView(searchFocused: $searchFocused, searchQuery: $appState.history.searchQuery,
                     isVisible: searchVisible)
        .opacity(searchVisible ? 1 : 0)
        .accessibilityHidden(!searchVisible)
        .frame(maxHeight: searchVisible ? nil : 0)
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

  private var captureStatus: some View {
    HStack(spacing: 8) {
      Image(systemName: ignoreEvents ? "pause.circle.fill" : "clipboard")
        .foregroundStyle(.orange)
      VStack(alignment: .leading, spacing: 2) {
        Text(captureStatusTitle)
          .font(.system(size: 11, weight: .semibold))
        Text(captureStatusDetail)
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      Button(captureStatusActionTitle) {
        if ignoreEvents {
          Clipboard.shared.setHistoryPaused(false)
        } else {
          appState.openPreferences(.history)
        }
      }
      .buttonStyle(.borderless)
      .pointingHandCursor()
      .font(.system(size: 11, weight: .semibold))
      .fixedSize()
      .accessibilityIdentifier(ignoreEvents ? "resume-clipboard-history" : "configure-clipboard-history")
    }
    .padding(10)
    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("clipboard-capture-status")
  }

  private var captureStatusTitle: LocalizedStringKey {
    if !ignoreEvents { return "Clipboard capture is off" }
    return ignoreOnlyNextEvent ? "Next copy will be skipped" : "Clipboard history paused"
  }

  private var captureStatusDetail: LocalizedStringKey {
    if !ignoreEvents { return "Choose what to save in History settings." }
    return ignoreOnlyNextEvent ? "History resumes after the next copy." : "New copies aren't being saved."
  }

  private var captureStatusActionTitle: LocalizedStringKey {
    if !ignoreEvents { return "Settings" }
    return ignoreOnlyNextEvent ? "Cancel" : "Resume"
  }
}
