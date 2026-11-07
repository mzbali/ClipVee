# ClipVee

Build, test and release steps are in `LOCAL_DEVELOPMENT.md`.

- Work on a branch and open a PR to `main`. The branch is protected, so direct pushes fail.
- CI builds and runs `MaccyTests`. It can't run `MaccyUITests` (they need Accessibility), so run the UI tests that cover your change locally before asking to merge.
