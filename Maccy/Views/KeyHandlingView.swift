import Sauce
import Defaults
import SwiftUI

struct KeyHandlingView<Content: View>: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool
  @ViewBuilder let content: () -> Content

  @State private var keyMonitor: Any?

  @Environment(AppState.self) private var appState

  var body: some View {
    content()
      .onAppear {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          guard !appState.popup.isClosed(),
                event.window === appState.appDelegate?.panel,
                NSApp.alertWindow == nil else { return event }
          return handleKeyEvent(event) ? nil : event
        }
      }
      .onDisappear {
        if let keyMonitor {
          NSEvent.removeMonitor(keyMonitor)
          self.keyMonitor = nil
        }
      }
  }

  // Handle the actual AppKit event before SwiftUI focus routing. The search
  // field may be hidden, or no SwiftUI control may currently own focus.
  private func handleKeyEvent(_ event: NSEvent) -> Bool {
    guard !appState.isEditingItem else { return false }

    if searchFocused {
      // Ignore input when candidate window is open
      // https://stackoverflow.com/questions/73677444/how-to-detect-the-candidate-window-when-using-japanese-keyboard
      if let inputClient = NSApp.keyWindow?.firstResponder as? NSTextInputClient,
         inputClient.hasMarkedText() {
        return false
      }
    }

    switch KeyChord(event) {
    case .clearHistory:
      if let item = appState.footer.items.first(where: { $0.title == "clear" }),
         item.confirmation != nil,
         let suppressConfirmation = item.suppressConfirmation {
        if suppressConfirmation.wrappedValue {
          item.action()
        } else {
          item.showConfirmation = true
        }
        return true
      } else {
        return false
      }
    case .clearHistoryAll:
      if let item = appState.footer.items.first(where: { $0.title == "clear_all" }),
         item.confirmation != nil,
         let suppressConfirmation = item.suppressConfirmation {
        if suppressConfirmation.wrappedValue {
          item.action()
        } else {
          item.showConfirmation = true
        }
        return true
      } else {
        return false
      }
    case .clearSearch:
      searchQuery = ""
      return true
    case .deleteCurrentItem:
      if appState.navigator.pasteStackSelected {
        appState.removePasteStack()
      } else {
        appState.deleteSelection()
      }
      return true
    case .deleteOneCharFromSearch:
      searchFocused = true
      _ = searchQuery.popLast()
      return true
    case .deleteLastWordFromSearch:
      searchFocused = true
      let newQuery = searchQuery.split(separator: " ").dropLast().joined(separator: " ")
      if newQuery.isEmpty {
        searchQuery = ""
      } else {
        searchQuery = "\(newQuery) "
      }

      return true
    case .moveToNext:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }

      appState.navigator.highlightNext()
      return true
    case .moveToLast:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }

      appState.navigator.highlightLast()
      return true
    case .moveToPrevious:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }

      appState.navigator.highlightPrevious()
      return true
    case .moveToFirst:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }

      appState.navigator.highlightFirst()
      return true
    case .extendToNext:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }
      guard AppState.shared.multiSelectionEnabled else {
        return false
      }
      appState.navigator.extendHighlightToNext()
      return true
    case .extendToLast:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }
      guard AppState.shared.multiSelectionEnabled else {
        return false
      }
      appState.navigator.extendHighlightToLast()
      return true
    case .extendToPrevious:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }
      guard AppState.shared.multiSelectionEnabled else {
        return false
      }
      appState.navigator.extendHighlightToPrevious()
      return true
    case .extendToFirst:
      guard NSApp.characterPickerWindow == nil else {
        return false
      }
      guard AppState.shared.multiSelectionEnabled else {
        return false
      }
      appState.navigator.extendHighlightToFirst()
      return true
    case .openPreferences:
      appState.openPreferences()
      return true
    case .pinOrUnpin:
      appState.togglePin()
      return true
    case .selectCurrentItem:
      appState.select(flags: .currentModifierFlags)
      return true
    case .close:
      appState.popup.close()
      return true
    case .togglePreview:
      appState.preview.togglePreview()
      return true
    default:
      ()
    }

    if let item = appState.history.pressedShortcutItem {
      appState.navigator.select(item: item)
      Task {
        try? await Task.sleep(for: .milliseconds(50))
        appState.history.select(item, flags: .currentModifierFlags)
      }
      return true
    }

    // Typing starts a search, so the field doesn't need focus (and a blinking caret) before that.
    focusSearchField(for: event)
    return false
  }

  /// Moves focus to the search field when `event` is text, so the key lands in it as usual.
  private func focusSearchField(for event: NSEvent) {
    guard Defaults[.showSearch],
          let panel = appState.appDelegate?.panel,
          (panel.firstResponder as? NSTextView)?.isFieldEditor != true,
          event.modifierFlags.isDisjoint(with: [.command, .control]),
          let characters = event.characters, !characters.isEmpty,
          characters.unicodeScalars.allSatisfy({ isTextScalar($0) }),
          let field = searchTextField(in: panel.contentView),
          panel.makeFirstResponder(field) else { return }

    // Focusing selects the whole text; keep what is typed so far and add to it.
    if let editor = panel.firstResponder as? NSTextView {
      editor.setSelectedRange(NSRange(location: editor.string.utf16.count, length: 0))
    }
    searchFocused = true
  }

  private func isTextScalar(_ scalar: Unicode.Scalar) -> Bool {
    // Arrow, function and other special keys report private-use characters.
    !CharacterSet.controlCharacters.contains(scalar) && !(0xF700...0xF8FF).contains(scalar.value)
  }

  private func searchTextField(in view: NSView?) -> NSTextField? {
    guard let view else { return nil }
    if let field = view as? NSTextField, field.isEditable, field.isEnabled { return field }
    for subview in view.subviews {
      if let field = searchTextField(in: subview) { return field }
    }
    return nil
  }
}
