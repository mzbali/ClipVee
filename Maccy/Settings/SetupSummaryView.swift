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
    VStack(spacing: 0) {
      SettingsPageView(title: "Check setup") {
        Text("Observed permission and configured settings")
          .font(.headline)
        Text("This check does not read the clipboard or history, request permission, or perform a test paste.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom, 8)

        row("Accessibility", value: summary.permissionStatus)
        row("Paste automatically", value: summary.autoPasteStatus)
        row("Capture", value: summary.captureStatus)
        row("Skip next copy", value: skipNextCopy ? "On" : "Off")
        row("Text", value: captureTypes(.text))
        row("Images", value: captureTypes(.images))
        row("Files", value: captureTypes(.files))
        row("Version", value: version)

        SettingsSectionHeader("Actual paste — not tested")
        Text(verbatim: summary.pasteExplanation)
          .fixedSize(horizontal: false, vertical: true)
        Text("Capture settings do not prove that an item will be saved. App, type and text filters still apply. Review General, History and Privacy to change these settings.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 8)
      }
      HStack {
        Spacer()
        Button("Done") { dismiss() }
          .keyboardShortcut(.defaultAction)
      }
      .padding(16)
    }
    .frame(width: 500, height: 600)
    .onReceive(trustTimer) { _ in accessibilityAllowed = AXIsProcessTrusted() }
  }

  private func row(_ title: LocalizedStringKey, value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      Text(title)
      Spacer(minLength: 8)
      Text(verbatim: value)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.trailing)
    }
    .padding(10)
    .settingsCardBackground()
    .accessibilityElement(children: .combine)
  }

  private func captureTypes(_ category: StorageType) -> String {
    SetupSummary.CaptureTypes(
      enabled: Set(enabledTypes.map(\.rawValue)),
      supported: Set(category.types.map(\.rawValue))
    ).rawValue
  }

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = info?["CFBundleVersion"] as? String ?? "Unknown"
    return "\(short) (\(build))"
  }
}
