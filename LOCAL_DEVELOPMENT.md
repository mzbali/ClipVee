# Maccy clipboard panel fork

Based on [Maccy 2.8.0](https://github.com/p0deje/Maccy/tree/2.8.0), under its MIT license.
This fork keeps clipboard capture and persistence, with a compact macOS panel inspired by Windows clipboard history.

- Command–Shift–V opens the panel in the middle of the frontmost window. Settings → Appearance → Popup at changes this. Windows opens at the text cursor, but the App Sandbox blocks reading another app's caret.
- Drag the panel by its header to move it. After a move, searching keeps the header in place.
- A copy made just before the shortcut (for example a Shottr screenshot) is picked up when the panel opens.
- Text and image cards have pin and delete controls. Formatted text also offers Paste as plain text.
- Each card shows its source app, when it was copied, and its quick-paste shortcut (⌘1–⌘9, or ⌘ plus the pin's letter). Hex colours such as `#FF8800` get a swatch; hovering a long item shows it in full.
- Arrow keys select; Return pastes into the originating app.
- Escape, another shortcut press, and clicking outside dismiss the panel.
- Clear all keeps pinned items.
- The search field appears only once you start typing. Metadata preview and the footer are hidden by default. There are no AI, emoji, or GIF tabs.
- Unpinned history keeps 200 items (Settings → Storage). Pins do not count towards that limit; about 29 receive a letter shortcut, and further pins are kept without one.

## Local build

Full Xcode is required. The script selects Xcode for this process without changing the system developer directory:

```sh
./scripts/build-local.sh
```

Output: `.build/DerivedData/Build/Products/Debug/Maccy Dev.app`.
The app uses `uk.co.mzbali.MaccyDev`, with separate preferences and sandbox storage from official Maccy.
It does not overwrite `/Applications/Maccy.app`, migrate its history, or use the official Sparkle update feed.
Updates to this development fork are manual builds.

Builds are ad-hoc signed by default. For a consistent local signing identity across rebuilds, set `MACCY_SIGN_IDENTITY` to an existing Apple Development certificate. Do not commit a certificate, private key, clipboard contents, or local test artifacts.

Direct paste requires Accessibility permission for **Maccy Dev**. Only run one app with Command–Shift–V registered at a time.

If Accessibility shows an enabled switch but the runner still reports no access, an earlier ad-hoc build may have a stale grant. Remove that entry in System Settings, then add the current signed app from the output folder above. Add **Maccy Dev.app** separately. Keep using the same signing identity for subsequent builds.

## Validation

Unit tests use an isolated pasteboard. UI tests temporarily save and restore the system clipboard, and use the disposable **Maccy Paste Target** editor rather than a real message box. UI tests require Accessibility permission for **MaccyUITests-Runner** to exercise real global input.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Maccy.xcodeproj -scheme Maccy -configuration Debug \
  -derivedDataPath .build/DerivedData -destination 'platform=macOS' \
  -only-testing:MaccyTests test-without-building
```

After the build, run the focused global-input tests with the same command, replacing `-only-testing:MaccyTests` with:

```sh
-only-testing:MaccyUITests/MaccyUITests/testHiddenHeaderKeyboardSelectionFromGlobalHotkey \
-only-testing:MaccyUITests/MaccyUITests/testKeyboardPasteWithoutInspectingPopup \
-only-testing:MaccyUITests/MaccyUITests/testHiddenHeaderOutsideClickDismissesAndCanReopen \
-only-testing:MaccyUITests/MaccyUITests/testImageCardPastesIntoOriginatingApp \
-only-testing:MaccyUITests/MaccyUITests/testCardPinAndClearPreservePinnedItemWithoutPasting \
-only-testing:MaccyUITests/MaccyUITests/testCardMenuDeletesWithoutPasting \
-only-testing:MaccyUITests/MaccyUITests/testCardListScrollsWithKeyboardAtBottomRight
```

The focused tests use Command–Shift–V with isolated test preferences; legacy UI tests use Command–Shift–C. The runner posts global keyboard events and verifies the destination editor's text or image attachments. Their success does not replace acceptance with a physical keyboard and direct image paste in the user's development apps.

To check the installed copy rather than the build output, prefix the command with `TEST_RUNNER_MACCY_UI_APP_PATH='/Applications/Maccy Dev.app'` and run `testInstalledKeyboardPasteWithoutInspectingPopup` plus `testImageCardPastesIntoOriginatingApp`. The installed-app test checks the actual running bundle path before sending global keys. Test history/preferences remain isolated.

## Windows behaviour reference

The scope is the clipboard-history portion described in [Microsoft's Windows 11 guide](https://www.microsoft.com/en-us/windows/learning-center/how-to-use-clipboard-history-in-windows-11) and [clipboard help](https://support.microsoft.com/en-gb/windows/apps/using-the-clipboard): text and image history, select to paste, persistent pins, and clearing unpinned entries. The unrelated emoji, GIF, and other tabs are outside this fork's UI.

## Current validation status

- PASS: local build and signature verification.
- PASS: 94 unit tests, including outside-click policy and isolated clipboard capture.
- PASS: visual inspection of the plain header, text card, pin/unpin, and item menu.
- PASS: global Command–Shift–V, both arrow directions, Return with direct text and image paste into the disposable editor, outside-click dismissal, Escape, six consecutive shortcut open/close cycles, and item-menu deletion.
- Accessibility repaired on 30 October 2026: an older ad-hoc signature had left a stale grant despite the runner switch appearing enabled. Both current signed apps now have working grants, including after a rebuild.
- PASS: Clear all keeps the panel open, preserves the pinned card, and removes unpinned cards without pasting. All 94 unit tests passed again after this change (`.build/AcceptanceFinal.xcresult`).
- PASS: a 16-item list at the bottom-right corner, jumps to first/last, 15 rapid Down presses, individual arrow navigation through every card, and direct paste of the oldest item (`.build/ScrollAcceptance4.xcresult`). The list now uses one outer non-lazy stack, with lazy row sections, and scroll tasks read the latest selection target after their delay.
- PASS: a sample pin survived a normal Maccy Dev quit and relaunch; the sample was then restored to its original unpinned state. The ordinary app also shows the image thumbnail correctly.
- PASS: after restarting into the diagnostic build, the user confirmed physical arrow selection works from T3. The ordinary-app log also confirms arrows and Return reached the panel's correct handlers. No focus fix was applied in this diagnostic rebuild, so the earlier failure's cause remains unconfirmed.
- PASS: the user confirmed physical Return pastes directly into T3 without Command–V on 30 October 2026. The earlier intermittent failure was not reproduced after restart; its cause remains unconfirmed.
- PASS: an additional global-key test sends the complete shortcut/Down/Up/Down/Return sequence without querying the popup first (`.build/UninspectedKeyboard.xcresult`). Focus diagnostics still report the app active in that session, so this does not reproduce the physical failure.
- Temporary focus/navigation logging was removed after physical acceptance.
- PASS: the final build without diagnostic logging passed global text paste without popup inspection, image paste, and outside-click/repeated-toggle checks (`.build/PublicationAcceptance.xcresult`).
- PASS: the copy installed at `/Applications/Maccy Dev.app` passed global text and image paste into the disposable editor (`.build/InstalledAcceptance.xcresult`). The test verified the running app's installed bundle path. Its signature verifies, Accessibility remained granted, and normal history was preserved after relaunch.

The local application is installed as **Maccy Dev** in `/Applications`. The official Homebrew app and Flycut were removed after acceptance. Their retired data, the Tahoe helper, disposable test app, build products, result bundles, and temporary logs were moved to the Bin during cleanup. Source, test support, dependency downloads, and the installed fork's history remain intact.

The UI runner's Accessibility grant was intentionally revoked after acceptance; only **Maccy Dev** retains the clipboard app's permission. Future desktop testing requires rebuilding the test apps and explicitly granting the runner access again. The historical result paths above describe completed runs; those artifacts are no longer in `.build`.

Source is maintained in [mzbali/Maccy](https://github.com/mzbali/Maccy), on the `clipboard-panel` branch. Updates are local builds; there is no automatic updater or notarized release.
