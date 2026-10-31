import AppKit
import Sparkle

@Observable
class SoftwareUpdater {
  static let shared = SoftwareUpdater()
  static var isAvailable: Bool { Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil }
  var automaticallyChecksForUpdates = false {
    didSet {
      // Writing the value Sparkle already has would count as the user's answer, and Sparkle
      // would then never ask whether to check automatically.
      guard Self.isAvailable, updater.automaticallyChecksForUpdates != automaticallyChecksForUpdates else { return }
      updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
    }
  }

  // The version a scheduled check found, while it waits for the user to look at it.
  private(set) var availableVersion: String?

  private var updater: SPUUpdater
  private var automaticallyChecksForUpdatesObservation: NSKeyValueObservation?

  private let reminder = UpdateReminder()
  private let updaterController: SPUStandardUpdaterController

  init() {
    updaterController = SPUStandardUpdaterController(
      startingUpdater: SoftwareUpdater.isAvailable,
      updaterDelegate: nil,
      userDriverDelegate: reminder
    )
    updater = updaterController.updater
    reminder.onChange = { [unowned self] version in
      availableVersion = version
    }
    automaticallyChecksForUpdatesObservation = updater.observe(
      \.automaticallyChecksForUpdates,
      options: [.initial, .new, .old]
    ) { [unowned self] _, change in
      guard change.newValue != change.oldValue, let newValue = change.newValue else {
        return
      }

      MainActor.assumeIsolated {
        self.automaticallyChecksForUpdates = newValue
      }
    }
  }

  // Also brings a waiting update to the front.
  func checkForUpdates() {
    guard Self.isAvailable else { return }
    NSApp.activate()
    updater.checkForUpdates()
  }
}

// Sparkle shows updates found soon after launch or after the Mac was idle. At other times its
// window would jump in front of the user's work, so the panel and the menu bar menu offer the
// update instead.
private final class UpdateReminder: NSObject, SPUStandardUserDriverDelegate {
  var onChange: (String?) -> Void = { _ in }

  var supportsGentleScheduledUpdateReminders: Bool { true }

  func standardUserDriverShouldHandleShowingScheduledUpdate(
    _ update: SUAppcastItem,
    andInImmediateFocus immediateFocus: Bool
  ) -> Bool {
    immediateFocus
  }

  func standardUserDriverWillHandleShowingUpdate(
    _ handleShowingUpdate: Bool,
    forUpdate update: SUAppcastItem,
    state: SPUUserUpdateState
  ) {
    guard !handleShowingUpdate else { return }
    onChange(update.displayVersionString)
  }

  func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
    onChange(nil)
  }

  func standardUserDriverWillFinishUpdateSession() {
    onChange(nil)
  }
}
