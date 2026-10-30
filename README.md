# Maccy clipboard panel

A personal fork of [Maccy 2.8.0](https://github.com/p0deje/Maccy/tree/2.8.0), with a macOS clipboard panel inspired by Windows 11 clipboard history.

## Everyday use

- **Command–Shift–V** opens the clipboard history.
- Text cards and image thumbnails show what you copied.
- **↑ / ↓** select an item; **Return** pastes it directly into the app you came from.
- Click an item to paste it, or use its pin and item-menu controls.
- **Escape**, the shortcut again, or a click outside closes the panel.
- **Clear all** removes unpinned items and keeps your pins.

The default panel is 360 points wide, near the bottom-right of the active screen. Position and size can be changed in settings. Search, the metadata sidebar, and the footer are hidden by default. There are no emoji, GIF, or AI tabs.

## Build and install

Requires macOS 14 or later and full Xcode. Build locally:

```sh
MACCY_SIGN_IDENTITY='<your Apple Development signing identity>' ./scripts/build-local.sh
```

The output is `.build/DerivedData/Build/Products/Debug/Maccy Dev.app`. Quit any running copy, then copy this app to `/Applications` and open it. Enable **Maccy Dev** in System Settings → Privacy & Security → Accessibility for direct paste. Use the same signing identity for later builds so permissions remain valid. Omitting the identity produces an ad-hoc build, which may require granting Accessibility again after rebuilding.

This fork uses the separate bundle identifier `uk.co.mzbali.MaccyDev`. Its settings and history are separate from official Maccy. Run only one clipboard manager with Command–Shift–V registered at a time.

This is a local development build, without a notarized release or automatic updates. Homebrew's `maccy` package installs the original app. Build this repository to use this version.

## Validation and development

See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) for the build and test workflow, signing details, and known limits. Validation includes 94 unit tests, focused desktop workflow checks with a disposable paste destination, and physical arrow/Return acceptance in T3. The earlier intermittent keyboard failure stopped after restarting; its cause remains unconfirmed.

## Credits and license

Clipboard capture, persistence, and the original application are from [Maccy by Alex Rodionov and contributors](https://github.com/p0deje/Maccy). This fork retains the [MIT license](LICENSE) and upstream attribution. The official project's website is [maccy.app](https://maccy.app); this fork is maintained separately.
