import Cocoa

extension NSImage {
  // Read our bundled icon directly: the system-provided application icon can
  // retain an older icon after replacing a local build at the same path.
  static let clipVeeAppIcon: NSImage = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
    .flatMap { NSImage(contentsOf: $0) } ?? NSApp.applicationIconImage

  static let gearshape = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "gearshape")
  static let externaldrive = NSImage(systemSymbolName: "externaldrive", accessibilityDescription: "externaldrive")
  static let paintpalette = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "paintpalette")
  static let nosign = NSImage(systemSymbolName: "nosign", accessibilityDescription: "nosign")
  static let gearshape2 = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "gearshape2")
}

extension NSImage.Name {
  static let clipboard = NSImage.Name("clipboard.fill")
  static let maccyStatusBar = NSImage.Name("StatusBarMenuImage")
  static let scissors = NSImage.Name("scissors")
  static let paperclip = NSImage.Name("paperclip")
}
