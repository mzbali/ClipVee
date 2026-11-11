import SwiftUI

// Values-only presentation, also used for offscreen previews with synthetic state.
struct SetupSummaryContent: View {
  let summary: SetupSummary
  let skipNextCopy: Bool
  let text: SetupSummary.CaptureTypes
  let images: SetupSummary.CaptureTypes
  let files: SetupSummary.CaptureTypes
  let version: String
  var done: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Check setup")
        .font(.title2.weight(.semibold))
        .accessibilityAddTraits(.isHeader)

      group("Permission") {
        row("Accessibility") {
          HStack(spacing: 6) {
            if summary.accessibilityAllowed {
              Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            }
            Text(verbatim: summary.permissionStatus)
          }
        }
      }

      group("Settings") {
        row("Paste automatically", value: summary.autoPasteStatus)
        Divider()
        row("Capture", value: summary.captureStatus)
        Divider()
        row("Skip next copy", value: skipNextCopy ? "On" : "Off")
        Divider()
        row("Text", value: text.rawValue)
        Divider()
        row("Images", value: images.rawValue)
        Divider()
        row("Files", value: files.rawValue)
      }

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Paste hasn’t been tested.")
          Text("Version \(version)")
            .font(.caption)
        }
        .foregroundStyle(.secondary)
        Spacer()
        Button("Done", action: done)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(20)
    .frame(width: 480)
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private func group<Content: View>(
    _ title: LocalizedStringKey, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0, content: content)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
  }

  private func row(_ title: LocalizedStringKey, value: String) -> some View {
    row(title) { Text(verbatim: value) }
  }

  private func row<Value: View>(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) -> some View {
    HStack {
      Text(title)
      Spacer(minLength: 16)
      value().foregroundStyle(.secondary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .accessibilityElement(children: .combine)
  }
}
