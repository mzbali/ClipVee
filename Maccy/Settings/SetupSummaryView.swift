import ApplicationServices
import Combine
import Defaults
import SwiftUI

struct SetupSummaryView: View {
  @Environment(\.dismiss) private var dismiss
  @Default(.pasteByDefault) private var autoPaste
  @Default(.ignoreEvents) private var capturePaused
  @Default(.ignoreOnlyNextEvent) private var skipNextCopy
  @Default(.enabledPasteboardTypes) private var enabledTypes
  @State private var accessibilityAllowed = AXIsProcessTrusted()

  private let trustTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  private var summary: SetupSummary {
    SetupSummary(accessibilityAllowed: accessibilityAllowed, autoPaste: autoPaste, capturePaused: capturePaused)
  }

  var body: some View {
    SetupSummaryContent(
      summary: summary,
      skipNextCopy: skipNextCopy,
      text: captureTypes(.text),
      images: captureTypes(.images),
      files: captureTypes(.files),
      version: version,
      done: { dismiss() }
    )
    .onReceive(trustTimer) { _ in accessibilityAllowed = AXIsProcessTrusted() }
  }

  private func captureTypes(_ category: StorageType) -> SetupSummary.CaptureTypes {
    SetupSummary.CaptureTypes(
      enabled: Set(enabledTypes.map(\.rawValue)),
      supported: Set(category.types.map(\.rawValue))
    )
  }

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = info?["CFBundleVersion"] as? String ?? "Unknown"
    return "\(short) (\(build))"
  }
}
