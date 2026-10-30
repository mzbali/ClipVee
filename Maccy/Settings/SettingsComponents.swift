import SwiftUI

// A settings row styled like the clipboard cards: an icon, a title with an
// optional description, and its control on the trailing edge.
struct SettingsCard<Control: View>: View {
  let icon: String
  let title: LocalizedStringKey
  var description: LocalizedStringKey?
  @ViewBuilder var control: Control

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 15))
        .foregroundStyle(.secondary)
        .frame(width: 24)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        if let description {
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      Spacer(minLength: 12)
      control
        .labelsHidden()
        .toggleStyle(.switch)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
    .settingsCardBackground()
    .accessibilityElement(children: .combine)
  }
}

struct SettingsSectionHeader: View {
  let title: LocalizedStringKey

  init(_ title: LocalizedStringKey) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(.system(size: 13, weight: .semibold))
      .padding(.top, 14)
      .padding(.bottom, 2)
      .accessibilityAddTraits(.isHeader)
  }
}

struct SettingsPageView<Content: View>: View {
  let title: LocalizedStringKey
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 22, weight: .semibold))
          .padding(.bottom, 10)
          .accessibilityAddTraits(.isHeader)
        content
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 24)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

extension View {
  func settingsCardBackground() -> some View {
    background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
      .overlay {
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
      }
  }
}
