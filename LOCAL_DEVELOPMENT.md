# ClipVee local development

## Daily development

Use the signed local Debug build in `/Applications/ClipVee.app` as the everyday app while iterating. After a change, run the relevant checks, rebuild with `CLIPVEE_SIGN_IDENTITY=ClipVee`, quit the running app, replace it and relaunch. Source edits only take effect after rebuilding and restarting.

Keep the published GitHub and Homebrew release stable. Gather fixes from everyday use, then test and publish a numbered release when requested. Installing a development build does not require a public version bump. Keep a rollback copy of the previous installed app under `.build/local-install-backups/`; both builds use the same history and settings, so run only one at a time.

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

Build first with `./scripts/build-local.sh`, which also builds the tests. Pass the same package flags as the build so the tests reuse its packages instead of downloading them again. Unit tests use their own pasteboard and don't touch your clipboard:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Maccy.xcodeproj -scheme ClipVee -configuration Debug \
  -derivedDataPath .build/DerivedData -destination 'platform=macOS' \
  -clonedSourcePackagesDirPath .build/SourcePackages -skipPackageUpdates \
  -only-testing:MaccyTests test-without-building
```

For a noninteractive check of the setup summary and supported card text sizes, run `bash test-support/check-setup-summary.sh`. It compiles only the value model and a command-line harness, without launching ClipVee, accessing the clipboard/history or reading app preferences. The normal unit test command above launches the app host; use the value-only check when app interaction is out of scope. Card size persistence is also covered by `CardTextSizeTests` in CI using a temporary preferences suite.

UI tests (`MaccyUITests`) press real keys and paste into a throwaway editor (`test-support/PasteTarget.swift`), so they take over the keyboard and mouse while they run. Quit the everyday ClipVee first; the tests save and restore your clipboard. They need Accessibility for **ClipVeeUITests-Runner**. To test the copy in `/Applications` rather than the build output, set `TEST_RUNNER_CLIPVEE_UI_APP_PATH=/Applications/ClipVee.app`.

## Refresh README media

The README GIF and the screenshots are recorded from the real app by `testReadmeDemoCapture`, which only runs when asked. It uses made-up snippets in a separate `Editor.app` and takes over the keyboard and mouse, so quit the everyday ClipVee first. Install the build you want to show in `/Applications`, then run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
TEST_RUNNER_CLIPVEE_UI_APP_PATH=/Applications/ClipVee.app \
TEST_RUNNER_CLIPVEE_CAPTURE_README=1 \
xcodebuild -project Maccy.xcodeproj -scheme ClipVee -configuration Debug \
  -derivedDataPath .build/DerivedData -destination 'platform=macOS' \
  -only-testing:MaccyUITests/MaccyUITests/testReadmeDemoCapture test-without-building \
  > .build/readme-capture.log 2>&1
./scripts/build-readme-media.sh
```

The script needs `ffmpeg`. It writes `docs/images/demo.gif` and the two images in `docs/screenshots/`. The website uses WebP copies of those screenshots: `cwebp -q 88 -resize 1440 0 docs/screenshots/panel.png -o .build/gh-pages/images/panel.webp`, and the same for `settings`. Check the media before publishing.

## Making a release

Releases are signed with a self-signed certificate called **ClipVee**, so macOS keeps ClipVee's Accessibility permission across updates. Create it once with `./scripts/create-signing-identity.sh`, and back it up from Keychain Access (File → Export Items): a new certificate would make every user turn Accessibility on again. It has no Apple Team ID, so the app turns off library validation to load Sparkle.

Updates are delivered by [Sparkle](https://sparkle-project.org). The app reads `appcast.xml` from the latest GitHub release, and only installs updates signed with the update key in your login keychain, whose public half is `SUPublicEDKey` in `Maccy/Info.plist`. Back the key up too, since without it existing copies can't update:

```sh
.build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x clipvee-update-key
```

Store the file in your password manager and delete it. On a new Mac, import it with `generate_keys -f clipvee-update-key`.

1. In a pull request, bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` and write the release notes as a short Markdown list in `docs/releases/<version>.md`. The app shows them when it offers the update. Merge it.
2. With `main` checked out at `origin/main`, run `./scripts/build-release.sh docs/releases/<version>.md`. It builds a universal Release copy, signed with the ClipVee certificate, and writes `.build/release/ClipVee-<version>.dmg`, `.zip` and a signed `appcast.xml`. The first run installs [dmgbuild](https://github.com/dmgbuild/dmgbuild) into `.build/dmg-venv`, and macOS asks once whether `generate_appcast` may use the update key. The disk image's background is `Design/dmg-background.png`, rendered from `Design/dmg-background.html`.
3. Run `./scripts/publish-release.sh`. It creates the GitHub release `v<version>` marked as latest, checks that the live `appcast.xml` lists the version with the zip's `length`, and opens a pull request in [mzbali/homebrew-tap](https://github.com/mzbali/homebrew-tap) that bumps the cask with the hash of the downloaded disk image. The tap's CI downloads it again; merge the PR once it passes. Copies already installed find the update within a day.
4. Update the website for anything user-facing. It lives on the `gh-pages` branch; check it out with `git worktree add .build/gh-pages gh-pages`, then commit and push there, and check the live site.

Before step 2, run the unit tests and the UI tests that cover what changed.

The app isn't notarised, so the README explains Gatekeeper's **Open Anyway** step.

## Code layout

The code keeps Maccy's target, module and folder names, so fixes from [Maccy](https://github.com/p0deje/Maccy) merge cleanly. Only user-facing names say ClipVee. Scope is the clipboard-history part of [Windows clipboard history](https://support.microsoft.com/en-gb/windows/apps/using-the-clipboard); emoji, GIF and other tabs are out of scope.
