import SwiftUI

struct AboutSettingsPane: View {
  private let sourceURL = URL(string: "https://github.com/mzbali/Maccy")!
  private let maccyURL = URL(string: "https://maccy.app")!
  private let licenseURL = URL(string: "https://github.com/mzbali/Maccy/blob/clipboard-panel/LICENSE")!

  private var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? ""
    let build = info?["CFBundleVersion"] as? String ?? ""
    return "\(short) (\(build))"
  }

  var body: some View {
    SettingsPageView(title: "About") {
      HStack(spacing: 16) {
        Image(nsImage: NSApp.applicationIconImage)
          .resizable()
          .frame(width: 64, height: 64)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          Text(verbatim: "ClipVee")
            .font(.system(size: 20, weight: .semibold))
          Text("Windows-style clipboard history for the Mac.")
            .foregroundStyle(.secondary)
          Text("Version \(version)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .settingsCardBackground()

      SettingsSectionHeader("Open source")
      SettingsCard(
        icon: "chevron.left.forwardslash.chevron.right",
        title: "Source code",
        description: "Report a problem or suggest an idea on GitHub."
      ) {
        Link("GitHub", destination: sourceURL)
      }
      SettingsCard(
        icon: "heart",
        title: "Based on Maccy",
        description: "ClipVee builds on Maccy by Alex Rodionov, released under the MIT License."
      ) {
        HStack(spacing: 12) {
          Link("Maccy", destination: maccyURL)
          Link("License", destination: licenseURL)
        }
      }
    }
  }
}

#Preview {
  AboutSettingsPane()
}
