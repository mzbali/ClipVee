import Defaults
import SwiftUI

// Shows where the panel opens on a sketch of the screen, next to the list of placements.
struct PopupPositionPicker: View {
  @Default(.popupPosition) private var popupPosition
  @Default(.windowPosition) private var windowPosition

  private static let order: [PopupPosition] = [.window, .lastPosition, .bottomRight, .cursor, .center, .statusItem]

  private let screenSize = CGSize(width: 268, height: 168)
  private let menuBarHeight: CGFloat = 0.06
  private let panelSize = CGSize(width: 0.2, height: 0.42)
  private let appWindow = CGRect(x: 0.08, y: 0.17, width: 0.56, height: 0.72)
  private let pointer = CGPoint(x: 0.7, y: 0.32)
  private let menuIcon = CGPoint(x: 0.8, y: 0.03)

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      screen
      VStack(spacing: 4) {
        ForEach(Self.order) { position in
          Button {
            popupPosition = position
          } label: {
            HStack {
              Text(position.description)
              Spacer(minLength: 0)
              if position == popupPosition {
                Image(systemName: "checkmark")
                  .foregroundStyle(Color.accentColor)
              }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
              position == popupPosition ? Color.accentColor.opacity(0.12) : .clear,
              in: RoundedRectangle(cornerRadius: 6)
            )
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(position == popupPosition ? .isSelected : [])
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(12)
    .settingsCardBackground()
  }

  private var screen: some View {
    let width = screenSize.width
    let height = screenSize.height
    let panel = panelFrame()

    return ZStack(alignment: .topLeading) {
      LinearGradient(
        colors: [Color(red: 0.62, green: 0.77, blue: 1), Color(red: 0.79, green: 0.71, blue: 1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Rectangle()
        .fill(.white.opacity(0.55))
        .frame(height: height * menuBarHeight)

      RoundedRectangle(cornerRadius: 4)
        .fill(.white.opacity(popupPosition == .window ? 0.7 : 0.45))
        .frame(width: width * appWindow.width, height: height * appWindow.height)
        .offset(x: width * appWindow.minX, y: height * appWindow.minY)

      if popupPosition == .statusItem {
        Image(systemName: "doc.on.clipboard")
          .font(.system(size: 7))
          .position(x: width * menuIcon.x, y: height * menuIcon.y)
      }

      miniPanel
        .frame(width: width * panelSize.width, height: height * panelSize.height)
        .offset(x: width * panel.minX, y: height * panel.minY)

      if popupPosition == .cursor {
        Image(systemName: "cursorarrow")
          .font(.system(size: 13))
          .shadow(color: .white, radius: 1)
          .position(x: width * pointer.x + 3, y: height * pointer.y + 5)
      }
    }
    .frame(width: width, height: height)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.12)) }
    .animation(.spring(duration: 0.35), value: popupPosition)
    .accessibilityHidden(true)
  }

  private var miniPanel: some View {
    VStack(spacing: 3) {
      ForEach(0..<4) { index in
        RoundedRectangle(cornerRadius: 2)
          .fill(index == 0 ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.1))
      }
    }
    .padding(4)
    .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
    .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(Color.accentColor, lineWidth: 1.5) }
    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
  }

  // The panel's frame in unit coordinates of the sketch, with the origin at the top left.
  private func panelFrame() -> CGRect {
    let size = panelSize
    var origin: CGPoint
    switch popupPosition {
    case .window:
      origin = CGPoint(x: appWindow.midX - size.width / 2, y: appWindow.midY - size.height / 2)
    case .center:
      origin = CGPoint(x: 0.5 - size.width / 2, y: (1 + menuBarHeight) / 2 - size.height / 2)
    case .lastPosition:
      // The saved anchor is the panel's top middle, relative to the visible frame from its bottom left.
      let top = menuBarHeight + (1 - windowPosition.y) * (1 - menuBarHeight)
      origin = CGPoint(x: windowPosition.x - size.width / 2, y: top)
    case .bottomRight:
      origin = CGPoint(x: 0.97 - size.width, y: 0.95 - size.height)
    case .cursor:
      origin = pointer
    case .statusItem:
      origin = CGPoint(x: menuIcon.x - 0.02, y: menuBarHeight)
    }
    origin.x = min(max(origin.x, 0.02), 0.98 - size.width)
    origin.y = min(max(origin.y, menuBarHeight), 0.98 - size.height)
    return CGRect(origin: origin, size: size)
  }
}

#Preview {
  PopupPositionPicker()
    .padding()
}
