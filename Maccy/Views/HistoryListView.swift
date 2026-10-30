import Defaults
import SwiftUI

struct HistoryListView: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase
  @Default(.pinTo) private var pinTo

  private var pinnedItems: [HistoryItemDecorator] { appState.history.pinnedItems }
  private var unpinnedItems: [HistoryItemDecorator] { appState.history.unpinnedItems }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          if let stack = appState.history.pasteStack, !stack.items.isEmpty {
            PasteStackView(stack: stack)
          }

          if pinTo == .top && !pinnedItems.isEmpty {
            PinsView(items: pinnedItems)
            if !unpinnedItems.isEmpty { Divider().padding(.vertical, 6) }
          }

          MultipleSelectionListView(items: unpinnedItems) { previous, item, next, index in
            HistoryItemView(item: item, previous: previous, next: next, index: index)
          }

          if pinTo == .bottom && !pinnedItems.isEmpty {
            if !unpinnedItems.isEmpty { Divider().padding(.vertical, 6) }
            PinsView(items: pinnedItems)
          }

          if pinnedItems.isEmpty && unpinnedItems.isEmpty {
            Text(searchQuery.isEmpty ? "Copy text or an image to get started." : "No matching items")
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, minHeight: 140)
          }
        }
        .padding(.vertical, 6)
        .background {
          GeometryReader { geo in
            Color.clear
              .task(id: appState.popup.needsResize) {
                try? await Task.sleep(for: .milliseconds(10))
                guard !Task.isCancelled else { return }
                if appState.popup.needsResize {
                  appState.popup.resize(height: geo.size.height)
                }
              }
          }
        }
      }
      .contentMargins(.leading, 10, for: .scrollIndicators)
      .task(id: appState.navigator.scrollTarget) {
        guard appState.navigator.scrollTarget != nil else { return }
        try? await Task.sleep(for: .milliseconds(10))
        guard !Task.isCancelled, let target = appState.navigator.scrollTarget else { return }
        proxy.scrollTo(target)
        appState.navigator.scrollTarget = nil
      }
      .onChange(of: scenePhase) {
        if scenePhase == .active {
          searchFocused = true
          appState.navigator.isKeyboardNavigating = true
          appState.navigator.select(item: appState.history.firstUnpinnedItem ?? appState.history.firstPinnedItem)
          appState.preview.enableAutoOpen()
          appState.preview.resetAutoOpenSuppression()
          appState.preview.startAutoOpen()
        } else {
          modifierFlags.flags = []
          appState.navigator.isKeyboardNavigating = true
          appState.preview.cancelAutoOpen()
        }
      }
    }
    .accessibilityIdentifier("history-scroll-view")
  }
}
