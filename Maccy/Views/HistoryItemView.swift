import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  @Environment(AppState.self) private var appState

  private func performSelect() {
    if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
      appState.navigator.addToSelection(item: item)
    } else {
      let flags = NSEvent.ModifierFlags.currentModifierFlags
      Task {
        appState.history.select(item, flags: flags)
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Group {
        if let image = item.thumbnailImage {
          Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 144, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityHidden(true)
        } else {
          Text(verbatim: item.text.isEmpty ? item.title : item.text.removingScalarsUnsafeForTitleLayout())
            .font(.system(size: 13))
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)
            .accessibilityHidden(true)
        }
      }

      HStack(spacing: 10) {
        if item.isPinned {
          Text("Pinned")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        Button {
          appState.history.togglePin(item)
        } label: {
          Image(systemName: item.isPinned ? "pin.fill" : "pin")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(item.isPinned ? Color.accentColor : .secondary)
        .help(item.isPinned ? "Unpin" : "Pin")
        .accessibilityLabel(item.isPinned ? "Unpin item" : "Pin item")
        .accessibilityIdentifier("pin-history-item")

        Menu {
          Button(item.isPinned ? "Unpin" : "Pin") { appState.history.togglePin(item) }
          Divider()
          Button("Delete", role: .destructive) { appState.history.delete(item) }
        } label: {
          Image(systemName: "ellipsis")
            .frame(width: 16)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Item actions")
      }
      .font(.system(size: 12))
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.7),
      in: RoundedRectangle(cornerRadius: 10)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(isSelected ? Color.accentColor.opacity(0.8) : Color.primary.opacity(0.08), lineWidth: 1)
    }
    .padding(.vertical, 4)
    .id(item.id)
    .contentShape(RoundedRectangle(cornerRadius: 10))
    .accessibilityElement(children: .contain)
    .accessibilityLabel(Text(item.accessibilityLabel))
    .accessibilityAddTraits(item.isSelected ? [.isSelected] : [])
    .accessibilityIdentifier("copy-history-item")
    .buttonAction(performSelect)
    .hoverSelectionId(item.id)
    .onAppear { item.ensureThumbnailImage() }
    .accessibilityAction(named: Text(item.isPinned ? "history_item_unpin_action" : "history_item_pin_action")) {
      appState.history.togglePin(item)
    }
    .accessibilityAction(named: Text("history_item_delete_action")) {
      appState.history.delete(item)
    }
  }

  private var isSelected: Bool { item.isSelected }
}
