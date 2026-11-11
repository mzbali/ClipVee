import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else { fatalError(message) }
}

// Exercise every permission/auto-paste/pause combination using values only.
for allowed in [false, true] {
  for autoPaste in [false, true] {
    for paused in [false, true] {
      let summary = SetupSummary(accessibilityAllowed: allowed, autoPaste: autoPaste, capturePaused: paused)
      expect(summary.permissionStatus == (allowed ? "Allowed" : "Not allowed"), "Permission status")
      expect(summary.autoPasteStatus == (autoPaste ? "On" : "Off — ordinary selection copies"), "Auto-paste status")
      expect(summary.captureStatus == (paused ? "Paused" : "Enabled in settings"), "Capture status")
      expect(summary.pasteExplanation.contains("Actual paste has not been tested."), "Never imply paste success")
      if !autoPaste {
        expect(summary.pasteExplanation.contains("only copies"), "Explain copy-only mode")
      } else if !allowed {
        expect(summary.pasteExplanation.contains("permission is missing"), "Explain missing permission")
      } else {
        expect(summary.pasteExplanation.contains("does not confirm"), "Allowed is not proof of paste")
      }
    }
  }
}
let supported: Set<String> = ["text", "html", "rtf"]
expect(SetupSummary.CaptureTypes(enabled: [], supported: supported) == .none, "Disabled category")
expect(SetupSummary.CaptureTypes(enabled: ["image"], supported: supported) == .none, "Unrelated types")
expect(SetupSummary.CaptureTypes(enabled: ["text"], supported: supported) == .some, "Partial category")
expect(SetupSummary.CaptureTypes(enabled: supported, supported: supported) == .all, "Complete category")
expect(SetupSummary.CaptureTypes(enabled: supported.union(["image"]), supported: supported) == .all,
       "Other categories do not change completeness")
expect(CardTextSize.allCases.map(\.rawValue) == [13, 15, 17], "Supported sizes")
expect(CardTextSize.standard.rawValue == 13, "Keep existing size")
expect(CardTextSize(rawValue: 99) == nil, "Reject unsupported sizes")
print("PASS: setup state combinations, capture categories and card sizes")
