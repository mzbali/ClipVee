# Preview readability and setup summary — PR #10

## Scope

- 13/15/17 pt card body text, default 13 pt; four-line previews retained.
- General → Check setup summarizes observed permission and configured paste/capture state, categories and version. Actual paste is explicitly untested.
- Owner rejected broad green success styling. Current revision uses Permission/Settings groups with separators, one small green dot for Accessibility Allowed, neutral On/Off preferences (Partly on for partial capture categories), a short untested-paste footer and subdued version. No individual outlined cards or setting checkmarks.
- Format diagnostics are deferred. No merge or release authorised.

## Evidence

- Head 0ef2ea7 passed CI: build, value-only setup checks and 111 tests in 13 suites. Codex exact-head review completed with no findings.
- Owner subsequently authorised signed local installation of that head. Installed bundle matched the build, signed with ClipVee, and launched from /Applications/ClipVee.app. History/settings were left in place; existing backups retained; additional app backup waived.
- Owner manual feedback: preview text sizing works. Newest copy first observed. This does not prove the older-item select/paste sequence.
- Previous green-status head f477055 passed CI and exact-head Codex review, then was installed on explicit owner instruction. Owner rejected its visual design; this revision supersedes it.
- Automated UI tests were not run: documented runner uses the system clipboard and real input, which conflict with the owner's isolation boundary.

## Open

- Current native-summary build-for-testing, value-only harness and diff check passed. Actual SwiftUI content was rendered offscreen using synthetic values only in light/dark and allowed/missing-permission states, fitting 480 x 437 points without clipping. No owner app, preferences, clipboard or input used; renderer windows were never shown.
- Push polish to PR #10 and finish current-head CI and Codex review.
- This polish is not reinstalled or visually tested. No reinstall, clipboard/input automation, merge or release is authorised by the feedback.
