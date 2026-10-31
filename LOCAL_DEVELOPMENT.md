# ClipVee local development

## Build

Full Xcode is required. The script uses it for this build only and leaves your system developer directory alone.

```sh
./scripts/build-local.sh
```

This writes `.build/DerivedData/Build/Products/Debug/ClipVee.app`. Copy it to `/Applications` and turn it on in System Settings → Privacy & Security → Accessibility.

Builds are signed ad hoc, so macOS forgets the Accessibility grant after every rebuild. To keep it, sign with the ClipVee release certificate (see [Making a release](#making-a-release)). macOS then treats the build and the released app as the same app, so you can switch between them without turning Accessibility on again. Quit the installed copy first, since both share the same history:

```sh
CLIPVEE_SIGN_IDENTITY=ClipVee ./scripts/build-local.sh
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

Releases are signed with a self-signed certificate called **ClipVee**, so macOS keeps ClipVee's Accessibility permission across updates. Create it once with `./scripts/create-signing-identity.sh`, and back it up from Keychain Access (File → Export Items): a new certificate would make every user turn Accessibility on again. It has no Apple Team ID, so the app turns off library validation to load Sparkle.

Updates are delivered by [Sparkle](https://sparkle-project.org). The app reads `appcast.xml` from the latest GitHub release, and only installs updates signed with the update key in your login keychain, whose public half is `SUPublicEDKey` in `Maccy/Info.plist`. Back the key up too, since without it existing copies can't update:

```sh
.build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x clipvee-update-key
```

Store the file in your password manager and delete it. On a new Mac, import it with `generate_keys -f clipvee-update-key`.

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. Write the release notes as a short Markdown list. The app shows them when it offers the update.
3. Run `./scripts/build-release.sh <notes.md>`. It builds a universal Release copy, signed with the ClipVee certificate, and writes `.build/release/ClipVee-<version>.dmg`, `.zip` and a signed `appcast.xml`. The first run installs [dmgbuild](https://github.com/dmgbuild/dmgbuild) into `.build/dmg-venv`, and macOS asks once whether `generate_appcast` may use the update key. The disk image's background is `Design/dmg-background.png`, rendered from `Design/dmg-background.html`.
4. Attach all three files to a GitHub release tagged `v<version>`, and mark it as the latest release. Copies already installed find the update within a day.
5. Update the version and `sha256` in [mzbali/homebrew-tap](https://github.com/mzbali/homebrew-tap).

The app isn't notarised, so the README explains Gatekeeper's **Open Anyway** step.

## Code layout

The code keeps Maccy's target, module and folder names, so fixes from [Maccy](https://github.com/p0deje/Maccy) merge cleanly. Only user-facing names say ClipVee. Scope is the clipboard-history part of [Windows clipboard history](https://support.microsoft.com/en-gb/windows/apps/using-the-clipboard); emoji, GIF and other tabs are out of scope.
