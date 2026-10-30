import Testing
import AppKit
import SwiftUI
@testable import Maccy

@Suite(.serialized)
enum SharedStateTests {}

extension SharedStateTests {
  @MainActor
  struct PopupDismissalTests {
    private func panel(onClose: @escaping () -> Void = {}) -> FloatingPanel<Text> {
      FloatingPanel(contentRect: NSRect(x: 100, y: 100, width: 300, height: 200), onClose: onClose) {
        Text("Popup dismissal fixture")
      }
    }

    @Test("An outside click closes even when the panel never became key")
    func closesNonKeyPanel() {
      var closeCount = 0
      let popup = panel { closeCount += 1 }
      popup.isPresented = true
      #expect(!popup.isKeyWindow)
      popup.dismissIfOutside(at: NSPoint(x: popup.frame.maxX + 20, y: popup.frame.midY))
      #expect(!popup.isPresented)
      #expect(closeCount == 1)
    }

    @Test("A click inside the panel does not dismiss it")
    func preservesInsideClicks() {
      let popup = panel()
      popup.isPresented = true
      defer { popup.close() }
      popup.dismissIfOutside(at: NSPoint(x: popup.frame.midX, y: popup.frame.midY))
      #expect(popup.isPresented)
    }

    @Test("Outside clicks preserve an active editor")
    func preservesEditor() {
      let popup = panel()
      popup.isPresented = true
      let previous = AppState.shared.isEditingItem
      AppState.shared.isEditingItem = true
      defer {
        popup.close()
        AppState.shared.isEditingItem = previous
      }
      popup.dismissIfOutside(at: NSPoint(x: popup.frame.maxX + 20, y: popup.frame.midY))
      #expect(popup.isPresented)
    }

    @Test("Outside clicks preserve a drag in progress")
    func preservesDrag() {
      let popup = panel()
      popup.isPresented = true
      let previous = AppState.shared.navigator.isDragAndDropInProgress
      AppState.shared.navigator.isDragAndDropInProgress = true
      defer {
        popup.close()
        AppState.shared.navigator.isDragAndDropInProgress = previous
      }
      popup.dismissIfOutside(at: NSPoint(x: popup.frame.maxX + 20, y: popup.frame.midY))
      #expect(popup.isPresented)
    }
  }
}
