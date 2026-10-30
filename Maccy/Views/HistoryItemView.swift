import Defaults
import KeyboardShortcuts
import SwiftHEXColors
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  @Environment(AppState.self) private var appState
  @Default(.showHexColorSwatch) private var showHexColorSwatch

  private static let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

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
        } else if let size = item.imagePixelSize {
          // Reserve the thumbnail's space while it is decoded, so the list does not jump.
          RoundedRectangle(cornerRadius: 6)
            .fill(.quaternary)
            .aspectRatio(size.width / size.height, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: 144, alignment: .leading)
            .accessibilityHidden(true)
        } else {
          HStack(alignment: .top, spacing: 8) {
            if let colorSwatch {
              RoundedRectangle(cornerRadius: 4)
                .fill(colorSwatch)
                .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(Color.primary.opacity(0.15)) }
                .frame(width: 18, height: 18)
            }
            Text(verbatim: item.text.isEmpty ? item.title : item.text.removingScalarsUnsafeForTitleLayout())
              .font(.system(size: 13))
              .lineLimit(4)
              .multilineTextAlignment(.leading)
              .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)
              // Show long items in full on hover; the card only fits four lines.
              .help(isLongText ? item.text.shortened(to: 1_000) : "")
          }
          .accessibilityHidden(true)
        }
      }

      HStack(spacing: 10) {
        HStack(spacing: 4) {
          if item.isPinned {
            Text("Pinned")
            Text(verbatim: "·")
          }
          if item.item.application != nil {
            AppImageView(appImage: item.applicationImage, size: CGSize(width: 12, height: 12))
          }
          // Refresh the relative time each minute.
          TimelineView(.everyMinute) { _ in
            Text(verbatim: source)
          }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        Spacer(minLength: 0)
        if let pasteShortcut {
          Text(verbatim: pasteShortcut)
            .font(.caption2.monospaced())
            .foregroundStyle(.tertiary)
            .help("Paste with \(pasteShortcut)")
            .accessibilityHidden(true)
        }
        Button {
          appState.history.togglePin(item)
        } label: {
          Image(systemName: item.isPinned ? "pin.fill" : "pin")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(item.isPinned ? Color.accentColor : .secondary)
        .help("\(item.isPinned ? "Unpin" : "Pin")\(shortcutHint(for: .pin))")
        .accessibilityLabel(item.isPinned ? "Unpin item" : "Pin item")
        .accessibilityIdentifier("pin-history-item")

        Menu {
          if hasFormatting {
            Button("Paste as plain text") {
              appState.history.select(item, flags: HistoryItemAction.pasteWithoutFormatting.modifierFlags)
            }
          }
          Button(item.isPinned ? "Unpin" : "Pin") { appState.history.togglePin(item) }
          Divider()
          Button("Delete", role: .destructive) { appState.delete(item) }
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
      appState.delete(item)
    }
  }

  private var isSelected: Bool { item.isSelected }
  private var isLongText: Bool { item.text.utf8.count > 160 || item.text.contains("\n") }

  // Only "#RRGGBB"-style values: bare words such as "bad" are valid hex too.
  private var colorSwatch: Color? {
    let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard showHexColorSwatch, title.hasPrefix("#"), title.utf8.count <= 9,
          let color = NSColor(hexString: title) else { return nil }
    return Color(nsColor: color)
  }

  // The ⌘ variant pastes with the default settings: ⌘1–⌘9 for recent items, letters for pins.
  private var pasteShortcut: String? {
    let description = item.shortcuts.first { $0.modifierFlags == [.command] }?.description ?? ""
    return description.isEmpty ? nil : description
  }

  // The timeline's date is the start of the minute, which can precede the copy.
  private var source: String {
    let elapsed = Date.now.timeIntervalSince(item.item.lastCopiedAt)
    let copiedAt = Self.relativeDateFormatter.localizedString(fromTimeInterval: elapsed < 60 ? 0 : -elapsed)
    return [item.application, copiedAt].compactMap { $0 }.joined(separator: " · ")
  }

  private func shortcutHint(for name: KeyboardShortcuts.Name) -> String {
    name.shortcut.map { " (\($0))" } ?? ""
  }
  // Check the stored types; parsing HTML for every card would block the main thread.
  private var hasFormatting: Bool { item.item.rtfData != nil || item.item.htmlData != nil }
}
