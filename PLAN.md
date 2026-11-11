# Preview readability and setup summary

Owner approved one PR with 13/15/17 pt card body text and a read-only Check setup panel. Keep 13 pt default. Format diagnostics are deferred. No merge, release, install, app launch, input, live clipboard/history, or user settings/permission changes are authorised.

## Scope

- Panel preference affects card body text only; preserve four-line previews.
- General → Check setup summarizes the observed Accessibility permission and configured auto-paste, pause, skip-next-copy, capture categories and app version.
- Explicitly distinguish settings/permission from actual paste, which is untested. No clipboard/history reads, export or permission prompt in the check.

## Verified locally

- App and test bundles compile with Xcode `build-for-testing`; no app/test host launched.
- Value-only command-line harness passes every permission/auto-paste/pause combination, capture category coverage, supported font sizes and unsupported-size rejection.
- `git diff --check` and shell syntax check pass.
- Independent Sol review: fixed modifier-key wording and added harness to CI. No findings rejected.
- Preference serialization regression test compiles and uses a unique temporary suite; execution belongs to CI because the normal local runner launches the app host.

## Open

- Open PR and finish current-head CI and connector review.
- Real layout, interaction, screenshots and end-to-end paste remain unverified under the owner's no-UI boundary. No installed-app, clipboard/history, settings/input, permission, merge/release/install interaction performed.
