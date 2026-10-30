import AppKit
@preconcurrency import ApplicationServices

struct Accessibility {
  static func check() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }
}
