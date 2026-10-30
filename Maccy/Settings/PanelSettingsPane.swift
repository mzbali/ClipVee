import AppKit
import SwiftUI
import Defaults

struct PanelSettingsPane: View {
  @Default(.popupPosition) private var popupPosition
  @Default(.popupScreen) private var popupScreen
  @Default(.pinTo) private var pinTo
  @Default(.menuIcon) private var menuIcon
  @Default(.showInStatusBar) private var showInStatusBar
  @Default(.showSearch) private var showSearch
  @Default(.searchVisibility) private var searchVisibility
  @Default(.windowPosition) private var windowPosition

  @State private var screens = NSScreen.screens

  private var searchField: Binding<SearchVisibility?> {
    Binding {
      showSearch ? searchVisibility : nil
    } set: {
      showSearch = $0 != nil
      if let visibility = $0 { searchVisibility = visibility }
    }
  }

  var body: some View {
    SettingsPageView(title: "Panel") {
      PopupPositionPicker()

      if popupPosition == .lastPosition {
        SettingsCard(
          icon: "arrow.uturn.backward",
          title: "Saved position",
          description: "Drag the panel by its header to move it. It opens wherever you left it."
        ) {
          Button("Reset") { _windowPosition.reset() }
            .disabled(windowPosition == _windowPosition.defaultValue)
        }
      }
      if screens.count > 1 && (popupPosition == .center || popupPosition == .lastPosition) {
        SettingsCard(icon: "display.2", title: "Screen") {
          Picker("Screen", selection: $popupScreen) {
            Text("Active screen").tag(0)
            ForEach(screens.indices, id: \.self) { index in
              Text(screens[index].localizedName).tag(index + 1)
            }
          }
          .fixedSize()
        }
      }

      SettingsSectionHeader("Cards")
      SettingsCard(icon: "pin", title: "Pinned items", description: "Keep pins above or below recent copies.") {
        Picker("Pinned items", selection: $pinTo) {
          ForEach(PinsPosition.allCases) { position in
            Text(position.description)
          }
        }
        .fixedSize()
      }
      SettingsCard(icon: "magnifyingglass", title: "Search field") {
        Picker("Search field", selection: searchField) {
          Text("While typing").tag(SearchVisibility?.some(.duringSearch))
          Text("Always").tag(SearchVisibility?.some(.always))
          Text("Never").tag(SearchVisibility?.none)
        }
        .fixedSize()
      }
      SettingsCard(icon: "paintpalette", title: "Colour swatches", description: "For hex codes such as #FF8800.") {
        Defaults.Toggle("Colour swatches", key: .showHexColorSwatch)
      }

      SettingsSectionHeader("Menu bar")
      SettingsCard(icon: "menubar.rectangle", title: "Menu bar icon") {
        HStack {
          Picker("Icon", selection: $menuIcon) {
            ForEach(MenuIcon.allCases) { icon in
              Image(nsImage: icon.image)
            }
          }
          .fixedSize()
          .disabled(!showInStatusBar)
          Defaults.Toggle("Menu bar icon", key: .showInStatusBar)
        }
      }
      SettingsCard(icon: "text.append", title: "Show latest copy next to the icon") {
        Defaults.Toggle("Show latest copy next to the icon", key: .showRecentCopyInMenuBar)
      }
      .disabled(!showInStatusBar)
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
      screens = NSScreen.screens
    }
  }
}

#Preview {
  PanelSettingsPane()
}
