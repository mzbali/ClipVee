import Foundation

// Values only: this model never queries permissions, preferences or the pasteboard.
nonisolated struct SetupSummary {
  enum CaptureTypes: String {
    case all = "On"
    case some = "Partly on"
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
  var autoPasteStatus: String { autoPaste ? "On" : "Off" }
  var captureStatus: String { capturePaused ? "Off" : "On" }
}

nonisolated enum CardTextSize: Int, CaseIterable {
  case standard = 13
  case larger = 15
  case largest = 17
}
