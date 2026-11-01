import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  nonisolated static let isTesting = CommandLine.arguments.contains("enable-testing")
  var panel: FloatingPanel<ContentView>!
  private var welcomeWindowController: WelcomeWindowController?
  private var statusItemMenuMonitor: Any?

  @objc
  private lazy var statusItem: NSStatusItem = {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.behavior = .removalAllowed
    statusItem.button?.action = #selector(performStatusItemClick)
    statusItem.button?.image = Defaults[.menuIcon].image
    statusItem.button?.imagePosition = .imageLeft
    statusItem.button?.target = self
    return statusItem
  }()

  // Base accessibility label for the status item; kept separate from the optional
  // dynamic `title` (recent copy text) so VoiceOver always announces something
  // meaningful even when that preference is off or the app is disabled.
  private func updateStatusItemAccessibilityLabel() {
    var accessibilityLabel = NSLocalizedString("status_item_accessibility_label", comment: "")
    if isStatusItemDisabled {
      accessibilityLabel += " — \(NSLocalizedString("status_item_disabled_accessibility_suffix", comment: ""))"
    }
    statusItem.button?.setAccessibilityLabel(accessibilityLabel)
  }

  private var isStatusItemDisabled: Bool {
    Defaults[.ignoreEvents] || Defaults[.enabledPasteboardTypes].isEmpty
  }

  private var statusItemVisibilityObserver: NSKeyValueObservation?

  func applicationWillFinishLaunching(_ notification: Notification) { // swiftlint:disable:this function_body_length
    #if DEBUG
    if Self.isTesting {
      SPUUpdater(hostBundle: Bundle.main,
                 applicationBundle: Bundle.main,
                 userDriver: SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil),
                 delegate: nil)
      .automaticallyChecksForUpdates = false
      // Start from a clean slate for the isolated testing preferences.
      UserDefaults.standard.removePersistentDomain(forName: Defaults.Keys.testingSuiteName)
    }
    #endif

    // Bridge FloatingPanel via AppDelegate.
    AppState.shared.appDelegate = self

    Clipboard.shared.onNewCopy { History.shared.add($0) }
    Clipboard.shared.start()

    Task {
      for await _ in Defaults.updates(.clipboardCheckInterval, initial: false) {
        Clipboard.shared.restart()
      }
    }

    statusItemVisibilityObserver = observe(\.statusItem.isVisible, options: .new) { _, change in
      if let newValue = change.newValue, Defaults[.showInStatusBar] != newValue {
        Defaults[.showInStatusBar] = newValue
      }
    }

    Task {
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }

    Task {
      for await value in Defaults.updates(.menuIcon, initial: false) {
        statusItem.button?.image = value.image
      }
    }

    synchronizeMenuIconText()
    Task {
      for await value in Defaults.updates(.showRecentCopyInMenuBar) {
        if value {
          statusItem.button?.title = AppState.shared.menuIconText
        } else {
          statusItem.button?.title = ""
        }
      }
    }

    updateStatusItemAccessibilityLabel()

    Task {
      for await _ in Defaults.updates(.ignoreEvents) {
        statusItem.button?.appearsDisabled = isStatusItemDisabled
        updateStatusItemAccessibilityLabel()
      }
    }

    Task {
      for await _ in Defaults.updates(.enabledPasteboardTypes) {
        statusItem.button?.appearsDisabled = isStatusItemDisabled
        updateStatusItemAccessibilityLabel()
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    migrateUserDefaults()
    disableUnusedGlobalHotkeys()
    // Start the updater now rather than when Settings opens, so scheduled checks run.
    _ = SoftwareUpdater.shared

    panel = FloatingPanel(
      contentRect: NSRect(origin: .zero, size: Defaults[.windowSize]),
      identifier: Bundle.main.bundleIdentifier ?? "org.p0deje.Maccy",
      statusBarButton: statusItem.button,
      onClose: { AppState.shared.popup.reset() }
    ) {
      ContentView()
    }
    showMenuOnSecondaryClick()

    // People updating from a version without this window have already set ClipVee up.
    if !Self.isTesting && !Defaults[.showedWelcome] {
      Defaults[.showedWelcome] = true
      if !AXIsProcessTrusted() {
        welcomeWindowController = WelcomeWindowController()
        welcomeWindowController?.show()
      }
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    panel.toggle(height: AppState.shared.popup.height)
    return true
  }

  func applicationWillTerminate(_ notification: Notification) {
    if Defaults[.clearOnQuit] {
      AppState.shared.history.clear()
    }
  }

  private func ensureMigration(key: String, _ action: () -> Void) {
    if Defaults[.migrations][key] != true {
      action()
      Defaults[.migrations][key] = true
    }
  }

  @MainActor
  private func migrateUserDefaults() {
    ensureMigration(key: "2024-07-01-version-2") {
      // Start 2.x from scratch.
      Defaults.reset(.migrations)

      // Inverse hide* configuration keys.
      // A fresh install has no legacy keys: retain this fork's defaults.
      if let hidden = UserDefaults.standard.object(forKey: "hideFooter") as? Bool {
        Defaults[.showFooter] = !hidden
      }
      if let hidden = UserDefaults.standard.object(forKey: "hideSearch") as? Bool {
        Defaults[.showSearch] = !hidden
      }
      if let hidden = UserDefaults.standard.object(forKey: "hideTitle") as? Bool {
        Defaults[.showTitle] = !hidden
      }
      UserDefaults.standard.removeObject(forKey: "hideFooter")
      UserDefaults.standard.removeObject(forKey: "hideSearch")
      UserDefaults.standard.removeObject(forKey: "hideTitle")
    }

    ensureMigration(key: "2025-07-04-add-jpeg-heic") {
      var types = Defaults[.enabledPasteboardTypes]
      if !types.isDisjoint(with: StorageType.images.types) {
        types.formUnion(StorageType.images.types)
      }
      Defaults[.enabledPasteboardTypes] = types
    }

    ensureMigration(key: "2026-08-12-cleanup-orphaned-history-item-contents") {
      _ = try? Storage.shared.cleanupOrphanedContents()
    }

    ensureMigration(key: "2026-08-31-sanitize-history-item-titles") {
      _ = try? Storage.shared.sanitizeTitles()
    }

    ensureMigration(key: "2026-09-15-remove-unpersistable-contents") {
      _ = try? Storage.shared.removeUnpersistableContents()
    }

    // The following defaults are not used in Maccy 2.x
    // and should be removed in 3.x.
    // - LaunchAtLogin__hasMigrated
    // - avoidTakingFocus
    // - saratovSeparator
    // - maxMenuItemLength
    // - maxMenuItems
  }

  @objc
  private func performStatusItemClick() {
    let modifierFlags = (NSApp.currentEvent?.modifierFlags ?? [])
      .union(NSEvent.modifierFlags)
      .intersection(.deviceIndependentFlagsMask)

    if modifierFlags.contains(.option) {
      Defaults[.ignoreEvents].toggle()

      if modifierFlags.contains(.shift) {
        Defaults[.ignoreOnlyNextEvent] = Defaults[.ignoreEvents]
      }

      return
    }

    panel.toggle(height: AppState.shared.popup.height)
  }

  // A right-click or Control-click gives the status item a menu just before AppKit handles the
  // click, so AppKit shows it like any menu bar menu. Opening it from the click's action would
  // leave the button waiting for a mouse-up the menu had taken, which stalls the app's timers.
  private func showMenuOnSecondaryClick() {
    statusItemMenuMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown]) { [weak self] event in
      guard let self, event.window != nil, event.window == statusItem.button?.window,
            event.type == .rightMouseDown || event.modifierFlags.contains(.control) else {
        return event
      }
      statusItem.menu = makeStatusItemMenu()
      return event
    }
  }

  private func makeStatusItemMenu() -> NSMenu {
    let menu = NSMenu()
    if let version = SoftwareUpdater.shared.availableVersion {
      addItem("Update to ClipVee \(version)…", symbol: "arrow.down.circle", action: #selector(checkForUpdates), to: menu)
      menu.addItem(.separator())
    }
    let open = addItem("Open Clipboard", symbol: "clipboard", action: #selector(openPanel), to: menu)
    open.setShortcut(KeyboardShortcuts.getShortcut(for: .popup))
    if Defaults[.ignoreEvents] {
      addItem("Resume Clipboard History", symbol: "play.circle", action: #selector(togglePause), to: menu)
    } else {
      addItem("Pause Clipboard History", symbol: "pause.circle", action: #selector(togglePause), to: menu)
    }
    let clear = addItem("Clear History…", symbol: "trash", action: #selector(confirmClearHistory), to: menu)
    clear.isEnabled = !AppState.shared.history.unpinnedItems.isEmpty
    menu.addItem(.separator())
    addItem("Settings…", symbol: "gearshape", action: #selector(openSettings), key: ",", to: menu)
    if SoftwareUpdater.isAvailable {
      addItem("Check for Updates…", symbol: "arrow.triangle.2.circlepath", action: #selector(checkForUpdates), to: menu)
    }
    addItem("About ClipVee", symbol: "info.circle", action: #selector(openAbout), to: menu)
    menu.addItem(.separator())
    addItem("Quit ClipVee", symbol: "xmark.rectangle", action: #selector(NSApplication.terminate), key: "q", to: menu)
    menu.autoenablesItems = false
    for item in menu.items where item.action != #selector(NSApplication.terminate) {
      item.target = self
    }
    menu.delegate = self
    return menu
  }

  // macOS 26 gives Settings and Quit icons of its own, and items without one would sit at a
  // different indent, so every item has one.
  @discardableResult
  private func addItem(_ title: String, symbol: String, action: Selector, key: String = "", to menu: NSMenu) -> NSMenuItem {
    let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
    item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
    return item
  }

  @objc
  private func openPanel() {
    panel.open(height: AppState.shared.popup.height)
  }

  @objc
  private func togglePause() {
    Defaults[.ignoreEvents].toggle()
  }

  @objc
  private func confirmClearHistory() {
    let alert = NSAlert()
    alert.messageText = "Clear clipboard history?"
    alert.informativeText = "Pinned items will be kept."
    alert.addButton(withTitle: "Clear").hasDestructiveAction = true
    alert.addButton(withTitle: "Cancel")
    // From the menu bar menu, macOS refuses a plain activate() and the alert would open unfocused.
    NSApp.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn {
      AppState.shared.history.clear()
    }
  }

  @objc
  private func openSettings() {
    AppState.shared.openPreferences()
  }

  @objc
  private func checkForUpdates() {
    SoftwareUpdater.shared.checkForUpdates()
  }

  @objc
  private func openAbout() {
    AppState.shared.openAbout()
  }

  private func synchronizeMenuIconText() {
    _ = withObservationTracking {
      AppState.shared.menuIconText
    } onChange: {
      DispatchQueue.main.async {
        if Defaults[.showRecentCopyInMenuBar] {
          self.statusItem.button?.title = AppState.shared.menuIconText
        }
        self.synchronizeMenuIconText()
      }
    }
  }

  private func disableUnusedGlobalHotkeys() {
    let names: [KeyboardShortcuts.Name] = [.delete, .pin, .togglePreview]
    KeyboardShortcuts.disable(names)

    NotificationCenter.default.addObserver(
      forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"),
      object: nil,
      queue: nil
    ) { notification in
      guard let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name,
            names.contains(name) else { return }
      MainActor.assumeIsolated {
        KeyboardShortcuts.disable(name)
      }
    }
  }
}

extension AppDelegate: NSMenuDelegate {
  // The menu blocks until it closes. Meanwhile the global shortcut would queue up and open the
  // panel afterwards, so the menu item handles it instead.
  func menuWillOpen(_ menu: NSMenu) {
    KeyboardShortcuts.disable(.popup)
  }

  // Without a menu, the next left-click opens the panel again.
  func menuDidClose(_ menu: NSMenu) {
    statusItem.menu = nil
    KeyboardShortcuts.enable(.popup)
  }
}
