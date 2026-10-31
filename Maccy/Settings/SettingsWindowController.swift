import AppKit
import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
  case general
  case panel
  case history
  case privacy
  case shortcuts
  case about

  var id: Self { self }

  var title: LocalizedStringKey {
    switch self {
    case .general: "General"
    case .panel: "Panel"
    case .history: "History"
    case .privacy: "Privacy"
    case .shortcuts: "Shortcuts"
    case .about: "About"
    }
  }

  var icon: String {
    switch self {
    case .general: "gearshape"
    case .panel: "rectangle.stack"
    case .history: "clock.arrow.circlepath"
    case .privacy: "hand.raised"
    case .shortcuts: "command"
    case .about: "info.circle"
    }
  }
}

@Observable
final class SettingsNavigation {
  var page: SettingsPage = .general
}

final class SettingsWindowController: NSWindowController {
  private let navigation = SettingsNavigation()

  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
      styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "ClipVee Settings"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isReleasedWhenClosed = false
    self.init(window: window)
    // Keep the window at its fixed size; with a full-size content view the
    // hosting controller would otherwise add the title bar height on top.
    let hostingController = NSHostingController(rootView: SettingsView(navigation: navigation))
    hostingController.sizingOptions = []
    window.contentViewController = hostingController
    window.setContentSize(NSSize(width: 720, height: 540))
    window.center()
  }

  func show(_ page: SettingsPage? = nil) {
    if let page {
      navigation.page = page
    }
    NSApp.activate()
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
  }
}

struct SettingsView: View {
  @Bindable var navigation: SettingsNavigation

  var body: some View {
    HStack(spacing: 0) {
      sidebar
      Divider()
      Group {
        switch navigation.page {
        case .general: GeneralSettingsPane()
        case .panel: PanelSettingsPane()
        case .history: HistorySettingsPane()
        case .privacy: PrivacySettingsPane()
        case .shortcuts: ShortcutsSettingsPane()
        case .about: AboutSettingsPane()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(Color(nsColor: .windowBackgroundColor))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea()
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 8) {
        Image(nsImage: NSApp.applicationIconImage)
          .resizable()
          .frame(width: 24, height: 24)
          .accessibilityHidden(true)
        Text(verbatim: "ClipVee")
          .font(.system(size: 14, weight: .semibold))
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 12)

      ForEach(SettingsPage.allCases) { item in
        SidebarRow(page: item, isSelected: navigation.page == item) { navigation.page = item }
      }
      Spacer()
    }
    .padding(.top, 44)
    .padding(.horizontal, 10)
    .frame(width: 190)
    .frame(maxHeight: .infinity)
    .background(.regularMaterial)
  }
}

// A sidebar row in the style of Windows 11 Settings: a soft highlight with an
// accent bar on its leading edge.
private struct SidebarRow: View {
  let page: SettingsPage
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: page.icon)
          .frame(width: 18)
          .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        Text(page.title)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .contentShape(Rectangle())
      .background(
        Color.primary.opacity(isSelected ? 0.08 : (isHovered ? 0.04 : 0)),
        in: RoundedRectangle(cornerRadius: 6)
      )
      .overlay(alignment: .leading) {
        if isSelected {
          Capsule()
            .fill(Color.accentColor)
            .frame(width: 3, height: 16)
        }
      }
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
