# ClipVee

Build, test and release steps are in `LOCAL_DEVELOPMENT.md`.

- Work on a branch and open a PR to `main`. The branch is protected, so direct pushes fail.
- Structure PR descriptions around why, what changed, and what was tested. Use plain language and correct grammar, and keep useful code names and concepts with short explanations.
- CI builds and runs `MaccyTests`. It can't run `MaccyUITests` (they need Accessibility), so run the UI tests that cover your change locally before asking to merge.
- Bring in Maccy fixes by merging `maccy/master` into a branch, then merge that PR with `pr-merge <pr> --merge` so Git keeps track of what is already in.
- Enable the pre-push compile check once per clone with `git config core.hooksPath .githooks` (worktrees share it). It runs `build-for-testing` on the committed tree, so commit first.
- In a worktree, build and test through [xcslot](https://github.com/ertembiyik/xcslot): put `xcslot` in front of the `xcodebuild` commands in `LOCAL_DEVELOPMENT.md`. It builds in a warm checkout at a fixed path, so a fresh worktree's first build takes about 13 s instead of a 45 s full compile, and it hands products back to the worktree's `.build/DerivedData`. If it is missing, install it with `brew install ertembiyik/tap/xcslot` or use plain `xcodebuild`.
