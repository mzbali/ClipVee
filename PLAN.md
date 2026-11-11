# Preview readability and setup summary — PR #10

## Scope

- 13/15/17 pt card body text, default 13 pt; four-line previews retained.
- General → Check setup summarizes observed permission and configured paste/capture state, categories and version. Actual paste is explicitly untested.
- Owner requested green text and success indicators for healthy observed/configured statuses. Version and actual-paste status stay neutral. Existing text and accessibility remain available.
- Format diagnostics are deferred. No merge or release authorised.

## Evidence

- Head 0ef2ea7 passed CI: build, value-only setup checks and 111 tests in 13 suites. Codex exact-head review completed with no findings.
- Owner subsequently authorised signed local installation of that head. Installed bundle matched the build, signed with ClipVee, and launched from /Applications/ClipVee.app. History/settings were left in place; existing backups retained; additional app backup waived.
- Owner manual feedback: preview text sizing works. Newest copy first observed. This does not prove the older-item select/paste sequence.
- Owner reported Check setup values visible but white. Healthy states now gain green text and a checkmark. Disabled/partial states stay neutral; configuration still does not imply paste success.
- Automated UI tests were not run: documented runner uses the system clipboard and real input, which conflict with the owner's isolation boundary.

## Open

- Local polish build-for-testing, value-only harness and diff check passed without launching apps.
- Push polish to PR #10 and finish current-head CI and Codex review.
- This polish is not reinstalled or visually tested. No reinstall, clipboard/input automation, merge or release is authorised by the feedback.
