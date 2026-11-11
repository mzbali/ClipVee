import Foundation

// Values only: this model never queries permissions, preferences or the pasteboard.
nonisolated struct SetupSummary {
  enum CaptureTypes: String {
    case all = "Enabled"
    case some = "Partly enabled"
    case none = "Off"

    init(enabled: Set<String>, supported: Set<String>) {
      let selected = enabled.intersection(supported)
      self = selected.isEmpty ? .none : (selected == supported ? .all : .some)
    }
  }

  let accessibilityAllowed: Bool
  let autoPaste: Bool
  let capturePaused: Bool

  var permissionStatus: String { accessibilityAllowed ? "Allowed" : "Not allowed" }
  var autoPasteStatus: String { autoPaste ? "On" : "Off — ordinary selection copies" }
  var captureStatus: String { capturePaused ? "Paused" : "Enabled in settings" }
  var pasteExplanation: String {
    if !autoPaste {
      return "Automatic paste is off. Choosing an item without modifiers only copies it. Actual paste has not been tested."
    }
    if !accessibilityAllowed {
      return "Automatic paste is on, but Accessibility permission is missing. Actual paste has not been tested."
    }
    return "macOS reports Accessibility permission is allowed. This does not confirm a working grant or paste into another app. Actual paste has not been tested."
  }
}

nonisolated enum CardTextSize: Int, CaseIterable {
  case standard = 13
  case larger = 15
  case largest = 17
}
