import AppKit

// A disposable app for global-key and outside-click tests. It contains no
// network actions or user documents, so a failed popup cannot send a message.
let application = NSApplication.shared
application.setActivationPolicy(.regular)
let presentation = CommandLine.arguments.contains("--presentation")
if presentation { application.appearance = NSAppearance(named: .darkAqua) }
let menu = NSMenu()
let applicationItem = NSMenuItem()
let applicationMenu = NSMenu()
applicationMenu.addItem(withTitle: "Quit Paste Target", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
applicationItem.submenu = applicationMenu
menu.addItem(applicationItem)
let editItem = NSMenuItem()
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
editItem.submenu = editMenu
menu.addItem(editItem)
application.mainMenu = menu

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 1100, height: 850),
    styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false
)
window.title = presentation ? "Weekend plan.txt" : "Maccy paste test target"
window.center()
final class PasteObserver: NSObject, NSTextViewDelegate {
  let summary = NSTextField(labelWithString: "Images: 0")

  func textDidChange(_ notification: Notification) {
    guard let editor = notification.object as? NSTextView, let storage = editor.textStorage else { return }
    var images = 0
    storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, _, _ in
      if value is NSTextAttachment { images += 1 }
    }
    summary.stringValue = "Images: \(images)"
  }
}

let observer = PasteObserver()
let content = window.contentView!
observer.summary.frame = NSRect(x: 20, y: 10, width: 300, height: 24)
observer.summary.setAccessibilityIdentifier("paste-summary")
observer.summary.isHidden = presentation
content.addSubview(observer.summary)
let editor = NSTextView(frame: NSRect(x: 0, y: 44, width: content.bounds.width, height: content.bounds.height - 44))
editor.autoresizingMask = [.width, .height]
editor.textContainerInset = NSSize(width: 20, height: 20)
editor.setAccessibilityIdentifier("paste-destination")
editor.isRichText = true
editor.importsGraphics = true
editor.delegate = observer
if presentation {
  // Keep the document at the top of the window instead of shrinking to fit after a paste.
  editor.isVerticallyResizable = false
  editor.textContainerInset = NSSize(width: 40, height: 40)
  let document = NSMutableAttributedString(string: "Weekend plan\n\n", attributes: [
    .font: NSFont.systemFont(ofSize: 28, weight: .semibold), .foregroundColor: NSColor.labelColor
  ])
  let bodyAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 19), .foregroundColor: NSColor.labelColor
  ]
  document.append(NSAttributedString(
    string: "Ferry to Sausalito on Saturday,\nthen lunch by the water.\n\nMeet at: ", attributes: bodyAttributes
  ))
  editor.textStorage?.setAttributedString(document)
  editor.typingAttributes = bodyAttributes
  editor.setSelectedRange(NSRange(location: document.length, length: 0))
}
content.addSubview(editor)
window.makeKeyAndOrderFront(nil)
window.makeFirstResponder(editor)
application.activate(ignoringOtherApps: true)
application.run()
