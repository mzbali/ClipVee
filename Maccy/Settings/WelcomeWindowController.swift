import ApplicationServices
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

// Shown on first launch: how to open the clipboard, the Accessibility permission ClipVee needs
// to paste, and whether to open it at login.
final class WelcomeWindowController: NSWindowController {
  convenience init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 460, height: 400),
      styleMask: [.titled, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "Welcome to ClipVee"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isReleasedWhenClosed = false
    self.init(window: window)
    window.contentViewController = NSHostingController(rootView: WelcomeView { [weak window] in window?.close() })
    window.center()
  }

  func show() {
    NSApp.activate()
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
  }
}

struct WelcomeView: View {
  let done: () -> Void

  // macOS doesn't announce the change, so check while the window is open.
  @State private var isTrusted = AXIsProcessTrusted()
  private let trustTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(spacing: 18) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable()
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
      VStack(spacing: 6) {
        Text("Welcome to ClipVee")
          .font(.system(size: 22, weight: .semibold))
          .accessibilityAddTraits(.isHeader)
        Text(openHint)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      VStack(spacing: 8) {
        SettingsCard(
          icon: "hand.raised",
          title: "Let ClipVee paste for you",
          description: isTrusted
            ? "Pick a card and ClipVee pastes it into the app you're using."
            : "Turn on ClipVee in System Settings → Privacy & Security → Accessibility. If it's on already, remove it with the minus button and add it again."
        ) {
          if isTrusted {
            Label("On", systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
          } else {
            Button("Allow…") { _ = Accessibility.check() }
          }
        }
        SettingsCard(
          icon: "power",
          title: "Open at login",
          description: "Keep your clipboard history ready, like on Windows."
        ) {
          LaunchAtLogin.Toggle { Text("Open at login") }
        }
      }
      Button("Get Started", action: done)
        .keyboardShortcut(.defaultAction)
        .controlSize(.large)
    }
    .padding(.horizontal, 28)
    .padding(.top, 36)
    .padding(.bottom, 24)
    .frame(width: 460)
    .onReceive(trustTimer) { _ in isTrusted = AXIsProcessTrusted() }
  }

  private var openHint: String {
    if let shortcut = KeyboardShortcuts.getShortcut(for: .popup) {
      return "Press \(shortcut) anywhere, or click ClipVee in the menu bar, to open your clipboard history."
    }
    return "Click ClipVee in the menu bar to open your clipboard history."
  }
}
