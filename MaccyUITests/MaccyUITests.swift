import ApplicationServices
import Carbon
import XCTest

// swiftlint:disable file_length
// swiftlint:disable type_body_length
@MainActor
private struct HistoryItemQuery {
  let query: XCUIElementQuery

  var allElementsBoundByIndex: [XCUIElement] {
    query.allElementsBoundByIndex
  }

  subscript(title: String) -> XCUIElement {
    query.matching(
      NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, "\(title), ")
    ).firstMatch
  }
}

@MainActor
class MaccyUITests: XCTestCase {
  let app: XCUIApplication = {
    if let path = ProcessInfo.processInfo.environment["CLIPVEE_UI_APP_PATH"] {
      return XCUIApplication(url: URL(fileURLWithPath: path))
    }
    return XCUIApplication()
  }()
  let pasteboard = NSPasteboard.general
  private lazy var pasteTarget = XCUIApplication(url: URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent(".build/PasteTarget.app"))
  private var savedClipboard: [NSPasteboardItem] = []
  private var didLaunch = false
  private var popupKeyCode = kVK_ANSI_C

  let copy1 = UUID().uuidString
  let copy2 = UUID().uuidString
  let copy3 = UUID().uuidString

  // https://hetima.github.io/fucking_nsimage_syntax
  let image1 = NSImage(named: "NSAddTemplate")!
  let image2 = NSImage(named: "NSBluetoothTemplate")!

  let file1 = URL.applicationSupportDirectory.appendingPathComponent("file1.txt")
  let file2 = URL.applicationSupportDirectory.appendingPathComponent("file2.txt")

  let rtf1 = NSAttributedString(string: "foo").rtf(
    from: NSRange(0...2),
    documentAttributes: [:]
  )
  let rtf2 = NSAttributedString(string: "bar").rtf(
    from: NSRange(0...2),
    documentAttributes: [:]
  )

  let html1 = "<a href='#'>foo</a>".data(using: .utf8)
  let html2 = "<a href='#'>bar</a>".data(using: .utf8)

  private var items: HistoryItemQuery {
    HistoryItemQuery(
      query: app.descendants(matching: .any).matching(identifier: "copy-history-item")
    )
  }

  var itemTitles: [String] {
    items.allElementsBoundByIndex
      .sorted(by: { $0.frame.origin.y < $1.frame.origin.y })
      .compactMap { $0.label.components(separatedBy: ", ").first }
  }

  override func setUp() async throws {
    try await super.setUp()
    continueAfterFailure = false
    savedClipboard = (pasteboard.pasteboardItems ?? []).map { original in
      let item = NSPasteboardItem()
      for type in original.types {
        if let data = original.data(forType: type) { item.setData(data, forType: type) }
      }
      return item
    }

    XCTAssertTrue(AXIsProcessTrusted(), "UI runner requires Accessibility access for real global input tests")

    try? "Hello world".write(to: file1, atomically: true, encoding: .utf8)
    try? "Hello world".write(to: file2, atomically: true, encoding: .utf8)

    app.launchArguments.append("enable-testing")
    setKeyboardShortcut("popup", keyCode: kVK_ANSI_C, modifiers: cmdKey | shiftKey)
    setKeyboardShortcut("pin", keyCode: kVK_ANSI_P, modifiers: optionKey)
    setKeyboardShortcut("delete", keyCode: kVK_Delete, modifiers: optionKey)
    setKeyboardShortcut("togglePreview", keyCode: kVK_Space, modifiers: controlKey)
    app.launch()
    didLaunch = true

    copyToClipboard(copy2)
    copyToClipboard(copy1)
    let fixture = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent(".build/PasteTarget.app")
    _ = try await NSWorkspace.shared.openApplication(at: fixture, configuration: NSWorkspace.OpenConfiguration())
    pasteTarget.activate()
  }

  override func tearDown() async throws {
    if let testRun, testRun.failureCount > 0 {
      let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
      screenshot.name = "Native failure screen"
      screenshot.lifetime = .keepAlways
      add(screenshot)
    }
    try await super.tearDown()

    if didLaunch { app.terminate() }
    if !NSRunningApplication.runningApplications(withBundleIdentifier: "uk.co.mzbali.MaccyPasteTarget").isEmpty {
      pasteTarget.terminate()
    }
    pasteboard.clearContents()
    pasteboard.writeObjects(savedClipboard)
  }

  func testPopupWithHotkey() throws {
    popUpWithHotkey()
    assertExists(items[copy1])
    assertExists(items[copy2])
  }

  func testCloseWithHotkey() throws {
    popUpWithMouse()
    assertExists(items[copy1])
    simulatePopupHotkey()
    assertNotExists(items[copy1])
  }

  func testPopupWithMenubar() {
    popUpWithMouse()
    assertExists(items[copy1])
    assertExists(items[copy2])
  }

  func testMenuBarPanelAndOptionsRespectPanelPositionAndPaste() throws {
    relaunchWithMinimalCenteredPopup(position: "center")
    popUpWithHotkey()
    let shortcutFrame = app.dialogs.firstMatch.frame
    app.typeKey(.escape, modifierFlags: [])
    assertPopupDismissed()

    let clicks: [(CGMouseButton, CGEventFlags, Bool)] = [
      (.left, [], false), (.right, [], true), (.left, .maskControl, true)
    ]
    for (button, modifiers, showsOptions) in clicks {
      pasteTarget.activate()
      let destination = pasteTarget.textViews["paste-destination"]
      destination.click()
      pasteTarget.typeKey("a", modifierFlags: .command)
      pasteTarget.typeKey(.delete, modifierFlags: [])
      try clickStatusItemWithMouse(button: button, modifiers: modifiers)
      if showsOptions {
        XCTAssertTrue(app.menuItems["Settings…"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.menuItems["Quit ClipVee"].exists)
        XCTAssertFalse(app.dialogs.firstMatch.exists)
        postKey(kVK_ANSI_O)
        postKey(kVK_Return)
      }
      waitUntilPoppedUp()
      let frame = app.dialogs.firstMatch.frame
      XCTAssertEqual(frame.minX, shortcutFrame.minX, accuracy: 2)
      XCTAssertEqual(frame.minY, shortcutFrame.minY, accuracy: 2)
      XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "clipboard-actions").firstMatch.exists)
      let card = items[copy1].frame
      postMouseClick(at: CGPoint(x: card.midX, y: card.midY))
      assertPopupDismissed()
      let pasted = NSPredicate { [self] _, _ in destination.value as? String == copy1 }
      expectation(for: pasted, evaluatedWith: nil)
      waitForExpectations(timeout: 3)
    }
  }

  private func openSettingsFromHeader() {
    app.descendants(matching: .any).matching(identifier: "clipboard-settings").firstMatch.click()
  }

  func testPauseBannerResumesCapturing() {
    popUpWithHotkey()
    app.descendants(matching: .any).matching(identifier: "clipboard-actions").firstMatch.click()
    app.menuItems["Pause Clipboard History"].click()
    XCTAssertTrue(app.staticTexts["Clipboard history paused"].waitForExistence(timeout: 3))
    copyToClipboard(copy3)
    assertNotExists(items[copy3])
    app.buttons["resume-clipboard-history"].click()
    XCTAssertFalse(app.staticTexts["Clipboard history paused"].exists)
    copyToClipboard(copy3)
    assertExists(items[copy3])
  }

  func testCaptureSettingsUpdatePanelGuidance() {
    popUpWithHotkey()
    openSettingsFromHeader()
    let settings = app.windows["ClipVee Settings"]
    settings.buttons["History"].click()
    for identifier in ["capture-text", "capture-images", "capture-files"] {
      let control = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
      control.coordinate(withNormalizedOffset: .zero)
        .withOffset(CGVector(dx: control.frame.width - 18, dy: control.frame.height / 2)).click()
      XCTAssertTrue((control.value as? String) == "0" || (control.value as? NSNumber)?.boolValue == false,
                    "Capture switch did not turn off: \(identifier)")
    }
    settings.buttons[XCUIIdentifierCloseWindow].click()
    pasteTarget.activate()
    popUpWithHotkey()
    let configure = app.buttons["configure-clipboard-history"]
    XCTAssertTrue(configure.waitForExistence(timeout: 3))
    configure.click()
    XCTAssertTrue(settings.buttons["History"].isSelected)
    let textControl = app.descendants(matching: .any).matching(identifier: "capture-text").firstMatch
    textControl.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: textControl.frame.width - 18, dy: textControl.frame.height / 2)).click()
    settings.buttons[XCUIIdentifierCloseWindow].click()
    pasteTarget.activate()
    popUpWithHotkey()
    XCTAssertFalse(configure.exists)
  }

  func testSearchModesAndEmptyRecovery() {
    popUpWithHotkey()
    chooseSearchVisibility("Always")
    let field = app.textFields.firstMatch
    XCTAssertTrue(field.exists)
    // The field waits for the user, without a caret, until typing starts.
    XCTAssertFalse(field.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
    postKey(kVK_ANSI_A)
    postKey(kVK_ANSI_B)
    assertSearchFieldValue("ab")
    for _ in 0..<5 { postKey(kVK_ANSI_X) }
    assertSearchFieldValue("abxxxxx")
    clearEmptySearch()
    XCTAssertTrue(app.textFields.firstMatch.exists)
    for _ in 0..<3 { postKey(kVK_ANSI_Z) }
    assertSearchFieldValue("zzz")

    chooseSearchVisibility("While typing")
    XCTAssertFalse(app.textFields.firstMatch.exists)
    for _ in 0..<2 { postKey(kVK_ANSI_Q) }
    assertSearchFieldValue("qq")
    clearEmptySearch()
    XCTAssertFalse(app.textFields.firstMatch.exists)

    chooseSearchVisibility("Never")
    XCTAssertFalse(app.textFields.firstMatch.exists)
    postKey(kVK_ANSI_Q)
    Thread.sleep(forTimeInterval: 0.3)
    XCTAssertFalse(app.textFields.firstMatch.exists)
    XCTAssertFalse(app.buttons["clear-empty-search"].exists)
    assertExists(items[copy1])
  }

  private func clearEmptySearch() {
    XCTAssertTrue(app.buttons["clear-empty-search"].waitForExistence(timeout: 3))
    // Filtering animates the panel height; click after the control has settled.
    Thread.sleep(forTimeInterval: 0.3)
    let clear = app.buttons["clear-empty-search"].frame
    postMouseClick(at: CGPoint(x: clear.midX, y: clear.midY))
    let cleared = NSPredicate { [self] _, _ in !app.buttons["clear-empty-search"].exists }
    expectation(for: cleared, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
  }

  private func chooseSearchVisibility(_ title: String) {
    openSettingsFromHeader()
    let settings = app.windows["ClipVee Settings"]
    settings.buttons["Panel"].click()
    let picker = app.descendants(matching: .any).matching(identifier: "search-visibility").firstMatch
    let options = ["Always", "While typing", "Never"]
    guard let current = picker.value as? String, let currentIndex = options.firstIndex(of: current),
          let targetIndex = options.firstIndex(of: title) else {
      XCTFail("Search visibility picker has an unexpected value")
      return
    }
    picker.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).click()
    Thread.sleep(forTimeInterval: 0.3)
    // The native picker menu is outside the app's normal accessibility subtree.
    let distance = targetIndex - currentIndex
    for _ in 0..<abs(distance) { postKey(distance > 0 ? kVK_DownArrow : kVK_UpArrow) }
    postKey(kVK_Return)
    let selected = NSPredicate { _, _ in picker.value as? String == title }
    expectation(for: selected, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    settings.buttons[XCUIIdentifierCloseWindow].click()
    pasteTarget.activate()
    popUpWithHotkey()
  }

  func testSettingsReopensOnGeneral() {
    popUpWithHotkey()
    openSettingsFromHeader()
    let settings = app.windows["ClipVee Settings"]
    XCTAssertTrue(settings.waitForExistence(timeout: 3))
    settings.buttons["Panel"].click()
    settings.buttons[XCUIIdentifierCloseWindow].click()
    pasteTarget.activate()
    popUpWithHotkey()
    openSettingsFromHeader()
    XCTAssertTrue(settings.buttons["General"].isSelected)
    XCTAssertFalse(settings.buttons["Panel"].isSelected)
  }

  func testNewCopyIsAdded() {
    popUpWithMouse()
    let copy3 = UUID().uuidString
    copyToClipboard(copy3)
    assertExists(items[copy3])
    app.typeKey(.escape, modifierFlags: [])
    popUpWithMouse()
    assertExists(items[copy2])
  }

  func testSearch() {
    popUpWithMouse()
    search(copy2)
    assertSearchFieldValue(copy2)
    assertExists(app.staticTexts[copy2])
    assertNotExists(items[copy1])
  }

  func testSearchFiles() {
    copyToClipboard(file2)
    copyToClipboard(file1)
    popUpWithMouse()
    search(file2.lastPathComponent)
    assertExists(items[file2.absoluteString.removingPercentEncoding!])
    assertNotExists(items[file1.absoluteString.removingPercentEncoding!])
  }

  func testCopyWithClick() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    items[copy2].firstMatch.click()
    assertPasteboardStringEquals(copy2)
  }

  func testCopyWithEnter() {
    assertKeyboardPaste(keyCode: kVK_ANSI_KeypadEnter)
  }

  func testCopyWithReturn() {
    assertKeyboardPaste(keyCode: kVK_Return)
  }

  private func assertKeyboardPaste(keyCode: Int) {
    popUpWithHotkey()
    postKey(kVK_DownArrow)
    let selected = NSPredicate { [self] _, _ in items[copy2].isSelected }
    expectation(for: selected, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    // Send the physical key code to the nonactivating panel instead of asking
    // XCTest to activate the app and synthesize the text form of Enter.
    postKey(keyCode)
    assertPasteboardStringEquals(copy2)
    assertPopupDismissed()
    let pasted = NSPredicate { [self] _, _ in
      pasteTarget.textViews["paste-destination"].value as? String == copy2
    }
    expectation(for: pasted, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
  }

  func testCopyWithCommandShortcut() {
    popUpWithMouse()
    app.typeKey("2", modifierFlags: [.command])
    assertPasteboardStringEquals(copy2)
  }

  func testSearchAndCopyWithCommandShortcut() {
    popUpWithMouse()
    search(copy2)
    app.typeKey("1", modifierFlags: [.command])
    assertPasteboardStringEquals(copy2)
  }

  func testCopyImage() {
    copyToClipboard(image2)
    copyToClipboard(image1)
    popUpWithMouse()
    let allItems = items.allElementsBoundByIndex
    guard allItems.count > 1 else {
      XCTFail("Expected at least 2 history items, found \(allItems.count)")
      return
    }
    scrollIntoViewIfNeeded(allItems[1])
    hoverAndClick(allItems[1])
    assertPasteboardDataCountEquals(image2.tiffRepresentation!.count, forType: .tiff)
  }

  func testOCRRecognizesTextInImage() {
    copyToClipboard(textImage("Lighthouse"))
    popUpWithMouse()
    assertImageFound(bySearching: "lighthouse")
  }

  func testOCRCopiesRecognizedTextFromSidePanel() {
    copyToClipboard(textImage("Lighthouse"))
    popUpWithMouse()

    let imageItem = items.query.matching(NSPredicate(format: "label BEGINSWITH %@", "Image, ")).firstMatch
    assertExists(imageItem)
    hover(imageItem)

    let copyTextButton = app.buttons["Copy extracted text."].firstMatch
    XCTAssertTrue(copyTextButton.waitForExistence(timeout: 3), "Side panel has no copy extracted text button")
    expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: copyTextButton)
    waitForExpectations(timeout: 15)
    copyTextButton.click()

    assertExists(items["Lighthouse"])
    XCTAssertEqual(itemTitles.first, "Lighthouse")
    assertPasteboardStringEquals("Lighthouse")
  }

  func testCopyFile() {
    copyToClipboard(file2)
    copyToClipboard(file1)
    popUpWithMouse()

    XCTAssertEqual(Array(itemTitles.prefix(2)), [
      file1.absoluteString.removingPercentEncoding!,
      file2.absoluteString.removingPercentEncoding!
    ])
    scrollIntoViewIfNeeded(items[file2.absoluteString.removingPercentEncoding!].firstMatch)
    hoverAndClick(items[file2.absoluteString.removingPercentEncoding!].firstMatch)
    assertPasteboardStringEquals(file2.absoluteString, forType: .fileURL)
  }

  func testCopyRTF() {
    copyToClipboard(rtf2, .rtf)
    popUpWithHotkey()
    closePopupByClickingOutside()
    copyToClipboard(rtf1, .rtf)
    popUpWithHotkey()
    XCTAssertEqual(Array(itemTitles.prefix(2)), ["foo", "bar"])
    scrollIntoViewIfNeeded(items["bar"].firstMatch)
    hoverAndClick(items["bar"].firstMatch)
    XCTAssertEqual(pasteboard.data(forType: .rtf), rtf2)
  }

  func testCopyHTML() {
    copyToClipboard(html2, .html)
    copyToClipboard(html1, .html)
    popUpWithMouse()
    XCTAssertEqual(Array(itemTitles.prefix(2)), ["foo", "bar"])
    scrollIntoViewIfNeeded(items["bar"].firstMatch)
    hoverAndClick(items["bar"].firstMatch)
    assertPasteboardDataEquals(html2, forType: .html)
  }

  func testDownArrow() {
    popUpWithMouse()
    app.typeKey(.downArrow, modifierFlags: [])
    app.typeKey(.enter, modifierFlags: [])
    assertPasteboardStringEquals(copy2)
  }

  func testUpArrow() {
    popUpWithMouse()
    app.typeKey(.downArrow, modifierFlags: [])
    app.typeKey(.upArrow, modifierFlags: [])
    app.typeKey(.enter, modifierFlags: [])
    assertPasteboardStringEquals(copy1)
  }

  func testControlJ() {
    popUpWithMouse()
    app.typeKey("j", modifierFlags: [.control])
    app.typeKey(.enter, modifierFlags: [])
    assertPasteboardStringEquals(copy2)
  }

  func testControlK() {
    popUpWithMouse()
    app.typeKey("j", modifierFlags: [.control])
    app.typeKey("k", modifierFlags: [.control])
    app.typeKey(.enter, modifierFlags: [])
    assertPasteboardStringEquals(copy1)
  }

  func testDeleteEntry() {
    popUpWithMouse()
    app.typeKey(.delete, modifierFlags: [.option])
    assertNotExists(items[copy1])

    app.typeKey(.escape, modifierFlags: [])
    popUpWithMouse()
    assertNotExists(items[copy1])
  }

  func testDeleteEntryDuringSearch() {
    popUpWithMouse()
    search(copy2)
    app.typeKey(.delete, modifierFlags: [.option])
    assertNotExists(items[copy2])

    app.typeKey(.escape, modifierFlags: [])
    popUpWithMouse()
    assertNotExists(items[copy2])
  }

  func testClear() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    pin(copy2)
    hoverAndClick(app.buttons["Clear"].firstMatch)
    confirmClear()
    popUpWithMouse()
    assertNotExists(items[copy1])
    assertExists(items[copy2])
  }

  func testClearDuringSearch() {
    popUpWithMouse()
    search(copy2)
    hoverAndClick(app.buttons["Clear"].firstMatch)
    confirmClear()
    popUpWithMouse()
    assertNotExists(items[copy1])
    assertNotExists(items[copy2])
  }

  func testClearAll() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    pin(copy2)
    XCUIElement.perform(withKeyModifiers: [.shift]) {
      hoverAndClick(app.buttons["Clear all"].firstMatch)
    }
    confirmClear()
    popUpWithMouse()
    assertNotExists(items[copy1])
    assertNotExists(items[copy2])
  }

  func testPin() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    pin(copy2)
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy2, copy1])

    app.typeKey(.escape, modifierFlags: [])
    popUpWithMouse()
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy2, copy1])
  }

  func testPinDuringSearch() {
    popUpWithMouse()
    search(copy2)
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    pin(copy2)
    assertSearchFieldValue("")
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy2, copy1])
  }

  func testUnpin() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    pin(copy2)
    pin(copy2)
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy1, copy2])
  }

  func testReorderPinsByDragging() {
    popUpWithMouse()
    pin(copy1)
    pin(copy2)
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy1, copy2])

    drag(items[copy2].firstMatch, before: items[copy1].firstMatch)
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy2, copy1])

    app.typeKey(.escape, modifierFlags: [])
    popUpWithMouse()
    XCTAssertEqual(Array(itemTitles.prefix(2)), [copy2, copy1])
  }

  func testRemoveLastWordFromSearchWithControlW() {
    popUpWithMouse()
    search("foo bar")
    app.typeKey("w", modifierFlags: [.control])
    assertSearchFieldValue("foo ")
  }

  func testCommandVPastesSelectedItem() {
    popUpWithMouse()
    scrollIntoViewIfNeeded(items[copy2].firstMatch)
    hover(items[copy2].firstMatch)
    app.typeKey("v", modifierFlags: [.command])
    assertPasteboardStringEquals(copy2)
    assertPopupDismissed()
  }

  func testReadmeDemoCapture() async throws {
    try XCTSkipUnless(ProcessInfo.processInfo.environment["CLIPVEE_CAPTURE_README"] == "1",
                      "Run explicitly to refresh README media")
    let output = FileManager.default.temporaryDirectory.appendingPathComponent("ClipVeeReadmeCapture")
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    print("README_CAPTURE_DIR=\(output.path)")
    pasteTarget.terminate()
    // Cards name the app a copy came from by its file name, so the demo uses its own "Editor" copy.
    let editor = XCUIApplication(url: URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent(".build/Editor.app"))
    editor.launchArguments = ["--presentation"]
    editor.launch()
    defer { editor.terminate() }
    app.terminate()
    setKeyboardShortcut("popup", keyCode: kVK_ANSI_V, modifiers: cmdKey | shiftKey)
    app.launchArguments.append(contentsOf: ["-popupPosition", "cursor"])
    app.launch()
    editor.activate()
    copyToClipboard("#2563EB")
    copyToClipboard("10:30 by the Ferry Building clock")
    copyToClipboard("Weekend checklist: ferry tickets, camera, sunglasses.")
    let window = editor.windows["Weekend plan.txt"]
    XCTAssertTrue(window.waitForExistence(timeout: 3))
    let frame = window.frame
    let pointer = CGPoint(x: frame.minX + 690, y: frame.minY + 100)
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pointer, mouseButton: .left)?
      .post(tap: .cghidEventTap)
    var frames: [(String, TimeInterval)] = []
    let start = Date.now
    func record(seconds: TimeInterval) throws {
      let until = Date.now.addingTimeInterval(seconds)
      repeat {
        let name = String(format: "frame-%03d.png", frames.count)
        let time = Date.now.timeIntervalSince(start)
        try window.screenshot().pngRepresentation.write(to: output.appendingPathComponent(name))
        frames.append((name, time))
        Thread.sleep(forTimeInterval: 0.12)
      } while Date.now < until
    }
    try record(seconds: 0.8)
    simulatePopupHotkey()
    try record(seconds: 1.2)
    postKey(kVK_DownArrow)
    try record(seconds: 1.2)
    postKey(kVK_Return)
    try record(seconds: 1.6)
    assertPopupDismissed()
    let pasted = editor.textViews["paste-destination"].value as? String
    XCTAssertTrue(pasted?.hasSuffix("Meet at: 10:30 by the Ferry Building clock") == true)
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pointer, mouseButton: .left)?
      .post(tap: .cghidEventTap)
    popUpWithHotkey()
    if !items["10:30 by the Ferry Building clock"].isSelected { postKey(kVK_DownArrow) }
    XCTAssertTrue(items["10:30 by the Ferry Building clock"].isSelected)
    try record(seconds: 1.2)
    try window.screenshot().pngRepresentation.write(to: output.appendingPathComponent("panel.png"))
    var timeline = "ffconcat version 1.0\n"
    for index in frames.indices {
      let duration = index + 1 < frames.count ? frames[index + 1].1 - frames[index].1 : 1.6
      timeline += "file '\(frames[index].0)'\nduration \(duration)\n"
    }
    timeline += "file '\(frames.last!.0)'\n"
    try timeline.write(to: output.appendingPathComponent("frames.ffconcat"), atomically: true, encoding: .utf8)
    openSettingsFromHeader()
    let settings = app.windows["ClipVee Settings"]
    settings.buttons["Panel"].click()
    try settings.screenshot().pngRepresentation.write(to: output.appendingPathComponent("settings.png"))
  }

  func testDisablesOnOptionClickingMenubarIcon() throws {
    try clickStatusItemWithMouse(button: .left, modifiers: .maskAlternate)
    popUpWithHotkey()
    XCTAssertTrue(app.staticTexts["Clipboard history paused"].waitForExistence(timeout: 3))

    let copy3 = UUID().uuidString
    let copy4 = UUID().uuidString
    copyToClipboard(copy3)
    copyToClipboard(copy4)

    assertNotExists(items[copy3])
    assertNotExists(items[copy4])
    app.buttons["resume-clipboard-history"].click()
    copyToClipboard(copy3)
    assertExists(items[copy3])
  }

  func testDisablesOnlyForNextCopyOnOptionShiftClickingMenubarIcon() throws {
    try clickStatusItemWithMouse(button: .left, modifiers: [.maskAlternate, .maskShift])
    popUpWithHotkey()
    XCTAssertTrue(app.staticTexts["Next copy will be skipped"].waitForExistence(timeout: 3))

    let copy3 = UUID().uuidString
    let copy4 = UUID().uuidString
    copyToClipboard(copy3)
    copyToClipboard(copy4)

    assertNotExists(items[copy3])
    assertExists(items[copy4])
    XCTAssertFalse(app.staticTexts["Next copy will be skipped"].exists)
  }

  func testCreatesNewCopyOnEnterWhenSearchResultsAreEmpty() {
    popUpWithMouse()
    search("foo bar")
    app.typeKey(.return, modifierFlags: [])
    XCTAssertEqual(pasteboard.string(forType: .string), "foo bar")
    assertExists(items["foo bar"])
  }

  func testOpenAndClose() throws {
    // Simulate the popup hotkey press (Cmd + Shift + C).
    let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)!
    cDown.flags = [.maskCommand, .maskShift]
    cDown.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    // Release the 'C' key but keep the popup open.
    let cUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)!
    cUp.flags = [.maskCommand, .maskShift]
    cUp.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    // Release the 'Shift' key and assert that the popup remains open - "normal" mode.
    let shiftUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false)!
    shiftUp.flags = [.maskCommand] // Command remains active, Shift released
    shiftUp.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    // Release the 'CMD' key and assert that the popup remains open - "normal" mode.
    let commandUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: false)!
    commandUp.flags = []
    commandUp.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    // Press shortcut again and assert the window closes
    cDown.flags = [.maskCommand, .maskShift]
    cDown.post(tap: .cghidEventTap)

    assertPopupDismissed()
  }

  func testOpenAndSelectSecondItem() throws {
    // Simulate the popup hotkey press (Cmd + Shift + C).
    let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)!
    cDown.flags = [.maskCommand, .maskShift]
    cDown.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    let cUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)!
    cUp.flags = [.maskCommand, .maskShift]
    cUp.post(tap: .cghidEventTap)

    // Press C 1 more time while keeping the modifier keys pressed
    cDown.post(tap: .cghidEventTap)

    // Release all modifiers keys and assert that the popup closes.
    let modifiersUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false)!
    modifiersUp.flags = []
    modifiersUp.post(tap: .cghidEventTap)

    assertPopupDismissed()
    assertPasteboardStringEquals(copy2)
  }

  func testOpenAndSelectThirdItem() throws {
    copyToClipboard(copy3)

    // Simulate the popup hotkey press (Cmd + Shift + C).
    let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)!
    cDown.flags = [.maskCommand, .maskShift]
    cDown.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    let cUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)!
    cUp.flags = [.maskCommand, .maskShift]
    cUp.post(tap: .cghidEventTap)

    // Press C 2 more times while keeping the modifier keys pressed
    cDown.post(tap: .cghidEventTap)
    cUp.post(tap: .cghidEventTap)
    cDown.post(tap: .cghidEventTap)

    // Release all modifiers keys and assert that the popup closes.
    let modifiersUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false)!
    modifiersUp.flags = []
    modifiersUp.post(tap: .cghidEventTap)

    assertPopupDismissed()
    assertPasteboardStringEquals(copy2)
  }

  func testOpenAndSelectThirdItemRepeatedPress() throws {
    copyToClipboard(copy3)

    // Simulate the popup hotkey press (Cmd + Shift + C).
    let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)!
    cDown.flags = [.maskCommand, .maskShift]
    cDown.post(tap: .cghidEventTap)

    waitUntilPoppedUp()

    // Press C 2 more times while keeping the modifier keys pressed
    cDown.post(tap: .cghidEventTap)
    cDown.post(tap: .cghidEventTap)

    // Release all modifiers keys and assert that the popup closes.
    let modifiersUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false)!
    modifiersUp.flags = []
    modifiersUp.post(tap: .cghidEventTap)

    assertPopupDismissed()
    assertPasteboardStringEquals(copy2)
  }

  func testTogglePopupAndCloseOnClickOutside() {
    popUpWithHotkey()

    closePopupByClickingOutside()
    assertNotExists(items[copy1])

    // Assert that the hotkeys still work
    popUpWithHotkey()

    simulatePopupHotkey()
    assertPopupDismissed()
  }

  func testHiddenHeaderKeyboardSelectionFromGlobalHotkey() {
    relaunchWithMinimalCenteredPopup()
    popUpWithHotkey()
    postKey(kVK_DownArrow)
    let selected = NSPredicate { [self] _, _ in items[copy2].isSelected }
    expectation(for: selected, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_UpArrow)
    let previous = NSPredicate { [self] _, _ in items[copy1].isSelected }
    expectation(for: previous, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_DownArrow)
    expectation(for: selected, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_Return)
    assertPasteboardStringEquals(copy2)
    assertPopupDismissed()
    let destination = pasteTarget.textViews["paste-destination"]
    let pasted = NSPredicate { _, _ in destination.value as? String == self.copy2 }
    expectation(for: pasted, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
  }

  func testKeyboardPasteWithoutInspectingPopup() {
    relaunchWithMinimalCenteredPopup()
    // Do not query or activate Maccy between the hotkey and paste. App-targeted
    // accessibility inspection must not establish keyboard focus for this test.
    simulatePopupHotkey()
    Thread.sleep(forTimeInterval: 0.3)
    postKey(kVK_DownArrow)
    postKey(kVK_UpArrow)
    postKey(kVK_DownArrow)
    postKey(kVK_Return)
    Thread.sleep(forTimeInterval: 0.3)
    assertPasteboardStringEquals(copy2)
    let destination = pasteTarget.textViews["paste-destination"]
    let pasted = NSPredicate { _, _ in destination.value as? String == self.copy2 }
    expectation(for: pasted, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    assertPopupDismissed()
  }

  func testInstalledKeyboardPasteWithoutInspectingPopup() {
    let path = ProcessInfo.processInfo.environment["CLIPVEE_UI_APP_PATH"]
    XCTAssertEqual(path, "/Applications/ClipVee.app", "Run with TEST_RUNNER_CLIPVEE_UI_APP_PATH set")
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: "uk.co.mzbali.ClipVee")
    XCTAssertEqual(running.first?.bundleURL?.path, path, "Must exercise the installed application")
    testKeyboardPasteWithoutInspectingPopup()
  }

  func testImageCardPastesIntoOriginatingApp() {
    relaunchWithMinimalCenteredPopup()
    copyToClipboard(textImage("Clipboard image preview"))
    copyToClipboard(copy1)
    popUpWithHotkey()
    let imageItem = items.query.matching(NSPredicate(format: "label BEGINSWITH %@", "Image, ")).firstMatch
    assertExists(imageItem)
    postKey(kVK_DownArrow)
    let selected = NSPredicate { _, _ in imageItem.isSelected }
    expectation(for: selected, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_Return)
    assertPopupDismissed()
    let pasted = NSPredicate { _, _ in
      let summary = self.pasteTarget.staticTexts["paste-summary"]
      return summary.label == "Images: 1" || summary.value as? String == "Images: 1"
    }
    expectation(for: pasted, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
  }

  func testCardPinAndClearPreservePinnedItemWithoutPasting() {
    relaunchWithMinimalCenteredPopup()
    popUpWithHotkey()
    items[copy1].buttons["pin-history-item"].click()
    XCTAssertTrue(app.dialogs.firstMatch.exists, "Pinning must keep the panel open")
    XCTAssertEqual(pasteTarget.textViews["paste-destination"].value as? String, "")
    assertExists(items[copy1].buttons["Unpin item"])
    app.descendants(matching: .any).matching(identifier: "clipboard-actions").firstMatch.click()
    app.menuItems["Clear History…"].click()
    XCTAssertTrue(app.dialogs.firstMatch.sheets.staticTexts["Pinned items will be kept."].exists)
    app.dialogs.firstMatch.sheets.buttons["Clear"].click()
    assertExists(items[copy1])
    assertNotExists(items[copy2])
    postKey(kVK_Escape)
    assertPopupDismissed()
  }

  func testCardMenuDeletesWithoutPasting() {
    relaunchWithMinimalCenteredPopup()
    popUpWithHotkey()
    let menuButton = items[copy1].menuButtons["Item actions"]
    XCTAssertTrue(menuButton.waitForExistence(timeout: 3))
    let frame = menuButton.frame
    postMouseClick(at: CGPoint(x: frame.midX, y: frame.midY))
    // Native MenuButton.click() loses its parent query while the menu tracks.
    postKey(kVK_ANSI_D)
    Thread.sleep(forTimeInterval: 0.1)
    postKey(kVK_Return)
    assertNotExists(items[copy1])
    assertExists(items[copy2])
    XCTAssertEqual(pasteTarget.textViews["paste-destination"].value as? String, "")
    postKey(kVK_Escape)
    assertPopupDismissed()
    popUpWithHotkey()
    assertNotExists(items[copy1])
    assertExists(items[copy2])
  }

  func testHiddenHeaderOutsideClickDismissesAndCanReopen() {
    relaunchWithMinimalCenteredPopup()
    popUpWithHotkey()
    XCTAssertFalse(app.textFields.firstMatch.exists)
    closePopupByClickingOutside()
    assertPopupDismissed()
    popUpWithHotkey()
    postKey(kVK_Escape)
    assertPopupDismissed()
    for _ in 0..<6 {
      popUpWithHotkey()
      simulatePopupHotkey()
      assertPopupDismissed()
    }
  }

  func testCardListScrollsWithKeyboardAtBottomRight() {
    relaunchWithMinimalCenteredPopup(position: "bottomRight")
    for index in 0..<14 { copyToClipboard("Scroll fixture \(index)") }
    popUpWithHotkey()
    let panel = app.dialogs.firstMatch.frame
    let screen = NSScreen.main!
    XCTAssertEqual(panel.maxX, screen.visibleFrame.maxX - 20, accuracy: 3)
    XCTAssertEqual(panel.maxY, screen.frame.maxY - screen.visibleFrame.minY - 20, accuracy: 3)
    let oldestVisible = NSPredicate { [self] _, _ in
      items[copy2].exists && items[copy2].isSelected && items[copy2].isHittable
    }
    let newestVisible = NSPredicate { [self] _, _ in
      items["Scroll fixture 13"].exists && items["Scroll fixture 13"].isSelected
        && items["Scroll fixture 13"].isHittable
    }
    postKey(kVK_PageDown)
    expectation(for: oldestVisible, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_PageUp)
    expectation(for: newestVisible, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    for _ in 0..<15 { postKey(kVK_DownArrow) }
    expectation(for: oldestVisible, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    postKey(kVK_PageUp)
    expectation(for: newestVisible, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
    let titles = (0..<13).reversed().map { "Scroll fixture \($0)" } + [copy1, copy2]
    for title in titles {
      postKey(kVK_DownArrow)
      let visibleSelection = NSPredicate { [self] _, _ in
        items[title].exists && items[title].isSelected && items[title].isHittable
      }
      expectation(for: visibleSelection, evaluatedWith: nil)
      waitForExpectations(timeout: 3)
    }
    XCTAssertLessThanOrEqual(app.dialogs.firstMatch.frame.height, 440)
    postKey(kVK_Return)
    assertPopupDismissed()
    let destination = pasteTarget.textViews["paste-destination"]
    let pasted = NSPredicate { [self] _, _ in destination.value as? String == copy2 }
    expectation(for: pasted, evaluatedWith: nil)
    waitForExpectations(timeout: 3)
  }

  private func relaunchWithMinimalCenteredPopup(position: String = "window") {
    app.terminate()
    setKeyboardShortcut("popup", keyCode: kVK_ANSI_V, modifiers: cmdKey | shiftKey)
    app.launchArguments.append(contentsOf: [
      "hide-search-for-testing", "-popupPosition", position
    ])
    app.launch()
    copyToClipboard(copy2)
    copyToClipboard(copy1)
    pasteTarget.activate()
  }

  private func postKey(_ keyCode: Int) {
    let source = CGEventSource(stateID: .privateState)
    for down in [true, false] {
      let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: down)
      event?.flags = []
      event?.post(tap: .cghidEventTap)
    }
    Thread.sleep(forTimeInterval: 0.1)
  }

  private func popUpWithHotkey() {
    simulatePopupHotkey()
    waitUntilPoppedUp()
  }

  // KeyboardShortcuts persists JSON strings in UserDefaults.standard. Passing them
  // as launch arguments places them in the isolated, higher-priority NSArgumentDomain.
  private func setKeyboardShortcut(_ name: String, keyCode: Int, modifiers: Int) {
    if name == "popup" { popupKeyCode = keyCode }
    if let index = app.launchArguments.firstIndex(of: "-KeyboardShortcuts_\(name)") {
      app.launchArguments.removeSubrange(index...index + 1)
    }
    app.launchArguments.append(contentsOf: [
      "-KeyboardShortcuts_\(name)",
      #""{\"carbonKeyCode\":\#(keyCode),\"carbonModifiers\":\#(modifiers)}""#
    ])
  }

  // Click outside the popup to close it
  private func closePopupByClickingOutside() {
    let popup = app.dialogs.firstMatch
    guard popup.exists else {
      return
    }

    let popupFrame = popup.frame
    let screenWidth = NSScreen.screens.first?.frame.width ?? popupFrame.maxX + 100
    let margin: CGFloat = 50
    let targetX = popupFrame.maxX + margin < screenWidth
      ? popupFrame.maxX + margin
      : popupFrame.minX - margin
    popup.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: targetX - popupFrame.minX, dy: popupFrame.height / 2))
      .click()
  }

  private func popUpWithMouse() {
    clickStatusItem()
    waitUntilPoppedUp()
  }

  private var isRunningOnCI: Bool {
    ProcessInfo.processInfo.environment["CI"] == "true"
  }

  private func clickStatusItem() {
    if isRunningOnCI {
      pressStatusItemViaAccessibility()
      return
    }

    let statusItem = app.statusItems.firstMatch
    if statusItem.waitForExistence(timeout: 3), statusItem.isHittable {
      statusItem.click()
    } else {
      pressStatusItemViaAccessibility()
    }
  }

  private func clickStatusItemWithMouse(button: CGMouseButton, modifiers: CGEventFlags = []) throws {
    let running = try XCTUnwrap(
      NSRunningApplication.runningApplications(withBundleIdentifier: "uk.co.mzbali.ClipVee")
        .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
    )
    let statusItem = try XCTUnwrap(axStatusItem(of: AXUIElementCreateApplication(running.processIdentifier)))
    var rawPosition: CFTypeRef?
    var rawSize: CFTypeRef?
    XCTAssertEqual(AXUIElementCopyAttributeValue(statusItem, kAXPositionAttribute as CFString, &rawPosition), .success)
    XCTAssertEqual(AXUIElementCopyAttributeValue(statusItem, kAXSizeAttribute as CFString, &rawSize), .success)
    let positionValue = try XCTUnwrap(rawPosition)
    let sizeValue = try XCTUnwrap(rawSize)
    guard CFGetTypeID(positionValue) == AXValueGetTypeID(), CFGetTypeID(sizeValue) == AXValueGetTypeID() else {
      XCTFail("Status item has no accessible screen bounds")
      return
    }
    var position = CGPoint.zero
    var size = CGSize.zero
    // AX screen bounds and Quartz mouse events both use top-left screen coordinates.
    let axPosition = positionValue as! AXValue // swiftlint:disable:this force_cast
    let axSize = sizeValue as! AXValue // swiftlint:disable:this force_cast
    XCTAssertTrue(AXValueGetValue(axPosition, .cgPoint, &position))
    XCTAssertTrue(AXValueGetValue(axSize, .cgSize, &size))
    guard size.width > 0, size.height > 0 else {
      XCTFail("Status item has empty screen bounds")
      return
    }
    if position.y < 0 {
      // With an auto-hidden menu bar, AX reports the item above the screen.
      let reveal = CGPoint(x: position.x + size.width / 2, y: 1)
      CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: reveal, mouseButton: .left)?
        .post(tap: .cghidEventTap)
      let deadline = Date.now.addingTimeInterval(3)
      while position.y < 0 && Date.now < deadline {
        Thread.sleep(forTimeInterval: 0.1)
        var updated: CFTypeRef?
        if AXUIElementCopyAttributeValue(statusItem, kAXPositionAttribute as CFString, &updated) == .success,
           let updated, CFGetTypeID(updated) == AXValueGetTypeID() {
          let value = updated as! AXValue // swiftlint:disable:this force_cast
          _ = AXValueGetValue(value, .cgPoint, &position)
        }
      }
    }
    XCTAssertGreaterThanOrEqual(position.y, 0, "Menu bar did not reveal for a physical click")
    postMouseClick(at: CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2),
                   button: button, modifiers: modifiers)
  }

  private func postMouseClick(at point: CGPoint, button: CGMouseButton = .left, modifiers: CGEventFlags = []) {
    CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: button)?
      .post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.2)
    let types: [CGEventType] = button == .right ? [.rightMouseDown, .rightMouseUp] : [.leftMouseDown, .leftMouseUp]
    for type in types {
      let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button)
      event?.flags = modifiers
      event?.post(tap: .cghidEventTap)
    }
  }

  private func pressStatusItemViaAccessibility() {
    let pid = NSRunningApplication.runningApplications(withBundleIdentifier: "uk.co.mzbali.ClipVee")
      .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }?
      .processIdentifier
    guard let pid else {
      XCTFail("Maccy is not running")
      return
    }

    let appElement = AXUIElementCreateApplication(pid)
    let deadline = Date.now.addingTimeInterval(3)
    var statusItem = axStatusItem(of: appElement)
    while statusItem == nil && Date.now < deadline {
      Thread.sleep(forTimeInterval: 0.1)
      statusItem = axStatusItem(of: appElement)
    }
    guard let statusItem else {
      XCTFail("Maccy has no status item exposed via accessibility")
      return
    }

    let result = AXUIElementPerformAction(statusItem, kAXPressAction as CFString)
    XCTAssertEqual(result, .success, "Failed to press status item via accessibility")
  }

  private func axStatusItem(of appElement: AXUIElement) -> AXUIElement? {
    guard let extrasMenuBar = axElement(appElement, attribute: kAXExtrasMenuBarAttribute) else {
      return nil
    }

    var children: CFTypeRef?
    guard AXUIElementCopyAttributeValue(extrasMenuBar, kAXChildrenAttribute as CFString, &children) == .success else {
      return nil
    }
    return (children as? [AXUIElement])?.first
  }

  private func axElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
          let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
      return nil
    }
    return (value as! AXUIElement) // swiftlint:disable:this force_cast
  }

  private func simulatePopupHotkey() {
    let commandDown = CGEvent(
      keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: true)!
    let commandUp = CGEvent(
      keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: false)!
    let shiftDown = CGEvent(
      keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: true)!
    let shiftUp = CGEvent(
      keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false)!
    shiftDown.flags = [.maskCommand]
    shiftUp.flags = [.maskCommand]
    let cDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(popupKeyCode), keyDown: true)!
    let cUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(popupKeyCode), keyDown: false)!
    cDown.flags = [.maskCommand, .maskShift]
    cUp.flags = [.maskCommand, .maskShift]
    commandDown.post(tap: .cghidEventTap)
    shiftDown.post(tap: .cghidEventTap)
    cDown.post(tap: .cghidEventTap)
    cUp.post(tap: .cghidEventTap)
    shiftUp.post(tap: .cghidEventTap)
    commandUp.post(tap: .cghidEventTap)
  }

  private func waitUntilPoppedUp() {
    if !app.dialogs.firstMatch.waitForExistence(timeout: 3) {
      XCTFail("Maccy did not pop up")
    }
  }

  private func assertPopupDismissed() {
    if !app.dialogs.firstMatch.waitForNonExistence(timeout: 3) {
      XCTFail("Maccy did not dismiss")
    }
  }

  private func copyToClipboard(_ content: String) {
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
    waitTillClipboardCheck()
  }

  private func copyToClipboard(_ content: NSImage) {
    pasteboard.clearContents()
    pasteboard.setData(content.tiffRepresentation, forType: .tiff)
    waitTillClipboardCheck()
  }

  private func textImage(_ text: String) -> NSImage {
    let string = NSAttributedString(string: text, attributes: [
      .font: NSFont.boldSystemFont(ofSize: 48),
      .foregroundColor: NSColor.black
    ])
    let size = NSSize(width: string.size().width + 40, height: string.size().height + 40)
    return NSImage(size: size, flipped: false) { rect in
      NSColor.white.setFill()
      rect.fill()
      string.draw(at: NSPoint(x: 20, y: 20))
      return true
    }
  }

  private func assertImageFound(bySearching text: String) {
    let imageItem = items.query.matching(NSPredicate(format: "label BEGINSWITH %@", "Image, ")).firstMatch
    for _ in 0..<5 {
      search(text)
      if imageItem.waitForExistence(timeout: 2) {
        break
      }
      app.typeKey("w", modifierFlags: [.control])
      sleep(2)
    }
    XCTAssertTrue(imageItem.exists, "No image found by searching \"\(text)\"")
    XCTAssertEqual(items.allElementsBoundByIndex.count, 1)
  }

  private func copyToClipboard(_ content: URL) {
    pasteboard.clearContents()
    pasteboard.setData(content.dataRepresentation, forType: .fileURL)
    // WTF: The subsequent writes to pasteboard are not
    // visible unless we explicitly read the last one?!
    pasteboard.string(forType: .fileURL)
    waitTillClipboardCheck()
  }

  private func copyToClipboard(_ content: Data?, _ type: NSPasteboard.PasteboardType) {
    pasteboard.clearContents()
    pasteboard.setData(content, forType: type)
    waitTillClipboardCheck()
  }

  // Default interval for Maccy to check clipboard is 1 second
  private func waitTillClipboardCheck() {
    usleep(1_500_000)
  }

  private func pin(_ title: String) {
    hover(items[title].firstMatch)
    app.typeKey("p", modifierFlags: [.option])
    usleep(1_500_000)
  }

  private func drag(_ element: XCUIElement, before target: XCUIElement) {
    hover(element)
    let source = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let destination = target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
    source.click(forDuration: 0.5, thenDragTo: destination, withVelocity: .slow, thenHoldForDuration: 0.5)
    usleep(500_000)
  }

  private func hoverAndClick(_ element: XCUIElement) {
    let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    coordinate.hover()
    usleep(200_000)
    coordinate.click()
  }

  private func scrollIntoViewIfNeeded(_ element: XCUIElement) {
    guard element.exists else {
      return
    }

    let container = app.scrollViews["history-scroll-view"].firstMatch
    guard container.exists else {
      return
    }

    var attempts = 0
    while !container.frame.contains(element.frame) && attempts < 15 {
      // Negative deltaY scrolls down (reveals elements below the viewport).
      let delta: CGFloat = element.frame.midY > container.frame.midY ? -10 : 10
      container.scroll(byDeltaX: 0, deltaY: delta)
      usleep(100_000)
      attempts += 1
    }
  }

  private func hover(_ element: XCUIElement) {
    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).hover()
    usleep(50_000)
    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).hover()
    usleep(200_000)
  }

  private func search(_ string: String) {
    // NOTE: app.typeText is broken in Sonoma and causes some
    //       Chars to be submitted with a .command mask (e.g. 'p', 'k' or 'j')
    string.forEach {
      app.typeKey("\($0)", modifierFlags: [])
    }
    waitForSearch()
  }

  private func waitForSearch() {
    // NOTE: This is a hack and is flaky.
    // Ideally we should wait for a proper condition to detect that search has settled down.
    usleep(500000)  // wait for search throttle
  }

  private func assertExists(_ element: XCUIElement) {
    expectation(for: NSPredicate(format: "exists = 1"), evaluatedWith: element)
    waitForExpectations(timeout: 3)
  }

  private func assertNotExists(_ element: XCUIElement) {
    expectation(for: NSPredicate(format: "exists = 0"), evaluatedWith: element)
    waitForExpectations(timeout: 3)
  }

  private func assertNotVisible(_ element: XCUIElement) {
    expectation(
      for: NSPredicate(format: "(exists = 0) || (isHittable = 0)"), evaluatedWith: element)
    waitForExpectations(timeout: 3)
  }

  private func assertPasteboardDataEquals(
    _ expected: Data?, forType: NSPasteboard.PasteboardType = .string
  ) {
    let predicate = NSPredicate { (object, _) -> Bool in
      guard let copy = object as? Data else {
        return false
      }

      return self.pasteboard.data(forType: forType) == copy
    }
    expectation(for: predicate, evaluatedWith: expected)
    waitForExpectations(timeout: 3)
  }

  private func assertPasteboardDataCountEquals(
    _ expected: Int, forType: NSPasteboard.PasteboardType = .string
  ) {
    let predicate = NSPredicate { (object, _) -> Bool in
      guard let count = object as? Int else {
        return false
      }

      return self.pasteboard.data(forType: forType)!.count == count
    }
    expectation(for: predicate, evaluatedWith: expected)
    waitForExpectations(timeout: 3)
  }

  private func assertPasteboardStringEquals(_ expected: String?, forType: NSPasteboard.PasteboardType = .string) {
      let predicate = NSPredicate { (object, _) -> Bool in
        guard let copy = object as? String else {
          return false
        }
        return self.pasteboard.string(forType: forType) == copy
      }
      expectation(for: predicate, evaluatedWith: expected)
      waitForExpectations(timeout: 3)
    }

  private func assertSearchFieldValue(_ string: String) {
    XCTAssertEqual(app.textFields.firstMatch.value as? String, string)
  }

  private func confirmClear() {
    let button = app.buttons["confirmation-confirm"].firstMatch
    expectation(for: NSPredicate(format: "isHittable = 1"), evaluatedWith: button)
    waitForExpectations(timeout: 3)
    button.click()
  }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
