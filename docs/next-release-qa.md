# Next ClipVee release: acceptance check

Checked locally on 2026-11-02, macOS 26.7.1 on this MacBook. This report records the acceptance sweep for 1.0.4. The user reviewed the batch and authorized the app release, website publication and distribution updates on 2026-11-02.

## Results

- PASS: signed Debug build, installed bundle signature, and signed local Release build. The daily app is `/Applications/ClipVee.app`.
- PASS: all 103 unit tests in 12 suites, with a clean successful xcodebuild exit. Latest bundle: `.build/acceptance-final-validation.xcresult`; log: `.build/acceptance-final-validation.log`.
- PASS: 13 website checks: copy success, denied permission, unavailable Clipboard API, retry, 320px bounds, live Reduce Motion change, replay pause/resume reaching completed paste, normal looping, current public download link, all local images loading, and complete Homebrew-command visibility at 320/390/1280px. Logs: `.build/acceptance-web.log`, `.build/acceptance-web-wrap.log`.
- PASS: manual Settings, About and onboarding icon checks show the blue ClipVee V. General opens by default. Light and dark Settings/onboarding layouts were inspected; original Dark appearance was restored. Debug About shows Development build; local Release About omits it.
- PASS: manual empty-history/search guidance, paused banner/Resume, capture-off guidance and History settings deep link, Accessibility Allowed status, and privacy wording.
- PASS: all 17 selected native acceptance cases passed across the sweep. The final seven-case rerun with corrected hidden-search configuration completed with zero failures and a clean successful xcodebuild exit (`.build/acceptance-confirmed-config.xcresult`, `.build/acceptance-confirmed-config.log`).

## Native acceptance coverage

The native runner's Accessibility permission is now enabled. Tests use the installed signed Debug app, an in-memory history, isolated preferences and a disposable PasteTarget app. The clipboard is saved and restored for each test; real history is never cleared by the tests.

After testing, the normal installed Debug app was relaunched without test arguments. Its binary matches the built app and passes signature verification. The separate local Release preview was closed; its read-only About check left real app preferences unchanged (before/after exports compared equal). No test instance remains running.

The 17 selected acceptance cases cover:

1. Left-click panel, right-click/Control-click options, selected center placement, Open Clipboard from options, and actual card-click paste into the original app.
2. Pause banner, Resume, stopping capture while paused, and capture resuming afterward.
3. All capture switches disabled, immediate capture-off guidance, and opening History settings directly.
4. Search While typing/Always/Never, discovery hint, no-match guidance, Clear search and typing again without manually refocusing.
5. Settings reopening on General.
6. Global shortcut keyboard navigation and text paste without app-targeted AX inspection establishing focus.
7. Image selection and actual image paste into PasteTarget.
8. Pinning and Clear all preserve the pinned card and do not paste.
9. Item menu Delete removes the item, does not paste, and stays deleted after reopening.
10. Option-click pauses; Option-Shift-click skips only one external copy.
11. Keyboard scrolling and paste at bottom-right, including screen-edge position assertions.
12. Dismissal and repeated reopening with search hidden.
13. File, RTF and HTML clipboard formats, plus search and Command-number copy.

Evidence bundles: `.build/acceptance-sweep.xcresult` contains the original 103-unit/17-native sweep, including the initial failures; `.build/acceptance-targeted.xcresult` confirms capture integration and card deletion; `.build/acceptance-final-validation.xcresult` confirms search modes/focus recovery and all unit tests. `.build/acceptance-confirmed-config.xcresult` is the final rerun of the seven cases affected by hidden-search configuration. Earlier failed runs remain for diagnosis and must not be counted as passing runs.

## Fixes found during acceptance

- History settings previously suppressed Defaults propagation, leaving capture-off guidance stale. Capture switches now update the observed preference directly; integration coverage passes.
- Switching search visibility did not refresh the panel. Header now observes search visibility and passes that state to the search field; all three modes and Clear search focus recovery pass.
- The narrow website Homebrew command clipped. It now wraps fully at all three checked widths.
- The capture-status accessibility container swallowed its action identifier. The container now preserves child actions for native automation and assistive technology.
- Native test setup used `-showSearch NO`, which Foundation supplied as a string rather than a Bool. A Debug-only isolated test flag now explicitly disables search; tests assert that search is hidden and that bottom-right placement is actually used. Native menu tests use physical input to avoid XCTest activation changing the paste destination. The Clear search check waits for the panel resize animation before clicking.
- Permission timer files explicitly import Combine, eliminating their compiler warnings.

## Coverage limits and release gate

This is a targeted acceptance sweep, not the entire inherited UI suite. Paste results were checked in the disposable native target, not every third-party editor. Multi-monitor, fullscreen/Spaces, every placement variant, minimum-width resizing, denied/regranted Accessibility transitions, and long-running performance were not exhaustively tested. No signing/notarization or public-install acceptance is claimed from this local run.

Paid Developer ID signing/notarization remains deferred by the user until before wider promotion. No membership purchase, credentials or signing-identity change is part of this batch.

Release 1.0.4 is authorized. Distribution verification is recorded separately from the local acceptance evidence below.

## Follow-up review fixes

- Removed the terminal-command disclosure from Privacy settings. Pause, Resume and skip-next-copy remain available through the app controls.
- Fixed pause boundaries: resuming discards clipboard changes made while paused even if the polling timer has not observed them. Arming a one-copy pause also starts at the current clipboard version, so a previous pending copy cannot consume the skip.
- Regression tests reproduced both failures before the fix. All 105 unit tests now pass (`.build/pause-boundary-green.xcresult`, `.build/pause-boundary-green.log`); the signed Release build compiles (`.build/pause-boundary-release.log`). The intentionally failing pre-fix run is `.build/pause-boundary-red.xcresult`.
- Renamed the panel action to “Clear history…” and retained the confirmation that pinned items are kept. README and website wording, including the animated demo label, now match. The inherited footer's separate “Clear all” action actually removes pins as well and retains its distinct meaning.
- PASS: native pin/clear and Pause/Resume tests in `.build/pause-boundary-green.xcresult`. That run also exposed an intermittent AX status-item reopening failure in the old skip-next-copy test helper. Both modifier-click tests now use physical mouse input and assert the pause/skip banner before copying; both pass with a clean command exit in `.build/pause-boundary-mouse.xcresult` and `.build/pause-boundary-mouse.log`.
- PASS: visual inspection of the installed panel's new label and Privacy settings with no script disclosure. The updated signed Debug build is installed and normal daily-use ClipVee has been restored; no release or push was performed.
- Updated the website's reduced-motion demo end state: the pasted sentence stays visible while the clipboard reopens with the same text card selected. Replay resets the full sequence. The mobile end state gives the sentence enough space above the panel. Seven browser checks pass, covering the static end state, 320/390px visibility, replay, pause/resume, normal looping and live Reduce Motion changes (`.build/demo-end-state-check.log`). Desktop and narrow-mobile end-state screenshots were visually inspected. Website changes remain local.

## Release 1.0.4 preflight

- Signed universal release (Apple silicon and Intel), version 1.0.4 build 5: PASS.
- Disk image checksum and mounted app signature/version/binary/Applications shortcut: PASS.
- Existing app signing requirement and public update key are retained. The archive Ed25519 signature and signed appcast verify.
- Homebrew cask syntax and style: PASS. Distribution publication is authorized; public endpoint verification follows publication.
