# ClipVee local development

## Build

Full Xcode is required. The script uses it for this build only and leaves your system developer directory alone.

```sh
./scripts/build-local.sh
```

This writes `.build/DerivedData/Build/Products/Debug/ClipVee.app`. Copy it to `/Applications` and turn it on in System Settings → Privacy & Security → Accessibility.

Builds are signed ad hoc, so macOS forgets the Accessibility grant after every rebuild. To keep it, sign with your Apple Development certificate:

```sh
CLIPVEE_SIGN_IDENTITY='Apple Development: you@example.com (TEAMID)' ./scripts/build-local.sh
```

If Accessibility shows ClipVee as on but pasting still doesn't work, an old build has left a stale grant. Remove ClipVee from the list with the minus button, then add the current copy again.

To bring over history and settings from Maccy, quit both apps and run `scripts/migrate-history.sh`. Pass a bundle identifier to copy from a different build.

## Tests

Unit tests use their own pasteboard and don't touch your clipboard:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Maccy.xcodeproj -scheme ClipVee -configuration Debug \
  -derivedDataPath .build/DerivedData -destination 'platform=macOS' \
  -only-testing:MaccyTests test-without-building
```

UI tests (`MaccyUITests`) press real keys and paste into a throwaway editor (`test-support/PasteTarget.swift`), so they take over the keyboard while they run. They save and restore your clipboard. They need Accessibility for **ClipVeeUITests-Runner**. To test the copy in `/Applications` rather than the build output, set `TEST_RUNNER_CLIPVEE_UI_APP_PATH=/Applications/ClipVee.app`.

## Making a release

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. Run `./scripts/build-release.sh`. It builds a universal Release copy, signed ad hoc, and writes `.build/release/ClipVee-<version>.zip`.
3. Attach the zip to a GitHub release tagged `v<version>`.

The app isn't notarised, so the README explains Gatekeeper's **Open Anyway** step.

## Code layout

The code keeps Maccy's target, module and folder names, so fixes from [Maccy](https://github.com/p0deje/Maccy) merge cleanly. Only user-facing names say ClipVee. Scope is the clipboard-history part of [Windows clipboard history](https://support.microsoft.com/en-gb/windows/apps/using-the-clipboard); emoji, GIF and other tabs are out of scope.
