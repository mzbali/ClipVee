import Defaults
import KeyboardShortcuts
import SwiftUI

struct ListHeaderView: View {
  @FocusState.Binding var searchFocused: Bool
  @Binding var searchQuery: String
  let isVisible: Bool

  @Environment(AppState.self) private var appState
  @Environment(\.scenePhase) private var scenePhase

  @Default(.showTitle) private var showTitle
  @Default(.showSearch) private var showSearch

  var body: some View {
    HStack {
      if showTitle {
        Text(verbatim: "ClipVee")
          .foregroundStyle(.secondary)
          .padding(.leading, 5)
      }

      SearchFieldView(placeholder: "search_placeholder", query: $searchQuery)
        // A disabled field can't take focus, so typing does nothing while search is off.
        .disabled(!showSearch)
        .focused($searchFocused)
        .contentShape(Rectangle())
        .onTapGesture { searchFocused = true }
        .frame(maxWidth: .infinity)
        .onChange(of: scenePhase) {
          if scenePhase == .background && !searchQuery.isEmpty {
            searchQuery = ""
          }
        }
        // Only reliable way to disable the cursor. allowsHitTesting() does not work.
        // Move it above the panel: anywhere inside, the invisible field would take
        // clicks and stop the header from dragging the panel.
        .offset(y: isVisible ? 0 : -(appState.popup.headerHeight + Popup.itemHeight))
    }
  }
}
