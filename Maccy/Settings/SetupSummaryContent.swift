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
    VStack(alignment: .leading, spacing: 0) {
      Text("Check setup")
        .font(.system(size: 17, weight: .semibold))
        .accessibilityAddTraits(.isHeader)
        .padding(.bottom, 18)

      Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
        GridRow {
          label("Accessibility")
            .foregroundStyle(.secondary)
          HStack(spacing: 5) {
            if summary.accessibilityAllowed {
              Circle()
                .fill(.green)
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)
            }
            Text(verbatim: summary.permissionStatus)
              .fontWeight(.medium)
          }
        }
        .accessibilityElement(children: .combine)
        GridRow {
          label("Paste test")
            .foregroundStyle(.secondary)
          Text("Not tested")
            .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
      }

      Divider()
        .padding(.vertical, 14)

      Text("Settings")
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isHeader)
        .padding(.bottom, 10)

      Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
        setting("Paste automatically", value: summary.autoPasteStatus)
        setting("Skip next copy", value: skipNextCopy ? "On" : "Off")
        setting("Capture", value: summary.captureStatus)
        setting("Text", value: text.rawValue, subordinate: true)
        setting("Images", value: images.rawValue, subordinate: true)
        setting("Files", value: files.rawValue, subordinate: true)
      }

      HStack(alignment: .firstTextBaseline) {
        Text("Version \(version)")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
        Spacer()
        Button("Done", action: done)
          .keyboardShortcut(.defaultAction)
      }
      .padding(.top, 20)
    }
    .font(.system(size: 13))
    .padding(20)
    .frame(width: 360)
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private func label(_ title: LocalizedStringKey, indent: CGFloat = 0) -> some View {
    Text(title)
      .padding(.leading, indent)
      .frame(width: 146, alignment: .leading)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func setting(_ title: LocalizedStringKey, value: String, subordinate: Bool = false) -> some View {
    GridRow {
      label(title, indent: subordinate ? 12 : 0)
      Text(verbatim: value)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.system(size: subordinate ? 12 : 13))
    .foregroundStyle(subordinate ? Color.secondary : Color.primary)
    .accessibilityElement(children: .combine)
  }
}
