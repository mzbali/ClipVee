# Preview readability and setup summary — PR #10

## Scope

- 13/15/17 pt card body text, default 13 pt; four-line previews retained.
- General → Check setup summarizes observed permission and configured paste/capture state, categories and version. Actual paste is explicitly untested.
- Current design: compact 360pt inspector layout, 17pt title, aligned status/setting values, prominent Paste test → Not tested, one divider, neutral preferences, indented capture types and subdued version/Done footer. Only Accessibility Allowed gets a small green dot. No cards or per-row separators.
- Format diagnostics are deferred. No merge or release authorised.

## Evidence

- Head 0ef2ea7 passed CI: build, value-only setup checks and 111 tests in 13 suites. Codex exact-head review completed with no findings.
- Owner subsequently authorised signed local installation of that head. Installed bundle matched the build, signed with ClipVee, and launched from /Applications/ClipVee.app. History/settings were left in place; existing backups retained; additional app backup waived.
- Owner manual feedback: preview text sizing works. Newest copy first observed. This does not prove the older-item select/paste sequence.
- Previous green-status head f477055 passed CI and exact-head Codex review, then was installed on explicit owner instruction. Owner rejected its visual design; this revision supersedes it.
- Automated UI tests were not run: documented runner uses the system clipboard and real input, which conflict with the owner's isolation boundary.

## Current presentation revision

- T3 Sol design critique identified equal visual weighting, excess width and distant values. Main model applied a compact inspector layout and inspected actual native offscreen renders.
- Signed build-for-testing, existing value-only checks and diff check pass. Light/dark renders with allowed/missing permission and partial categories fit 360 x 350 points without clipping. Data is synthetic; renderer windows never shown. Evidence: .build/setup-compact-preview/.
- Security investigation remains separate. No flagged app was reopened, protection bypassed or installed bundle changed for this revision.

## Open

- Push this visual revision to PR #10 and finish current-head CI and Codex review.
- No interactive owner-app checks, installation, merge or release authorised for this revision.
