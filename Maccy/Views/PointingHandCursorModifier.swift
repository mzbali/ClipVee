import SwiftUI

extension View {
  /// Shows the pointing-hand cursor over clickable controls such as icon buttons.
  func pointingHandCursor() -> some View {
    modifier(PointingHandCursorModifier())
  }
}

private struct PointingHandCursorModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(macOS 15.0, *) {
      content.pointerStyle(.link)
    } else {
      content.onContinuousHover { phase in
        switch phase {
        case .active:
          NSCursor.pointingHand.set()
        case .ended:
          NSCursor.arrow.set()
        }
      }
    }
  }
}
