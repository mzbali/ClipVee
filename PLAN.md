# Card preview text size — PR #10

## Scope

- Panel → Cards → Preview text size: 13, 15 or 17 pt. Default 13 pt, the previous fixed size.
- Changes only the card body text; four-line previews, titles, badges and layout are unchanged.
- Stored in the existing preferences suite under `cardTextSize` (`CardTextSize`, `Maccy/CardTextSize.swift`). Unknown stored values fall back to 13 pt.
- The earlier General → Check setup summary was removed at the owner's request: it gave the user nothing they could act on.

## Constraints

- `CardTextSize` and its `Defaults.Serializable` conformance stay explicitly `nonisolated`; CI's Xcode 26.6 needs this.
- No app launch, installation, merge or release authorised for this revision. Local verification is build-only; app-hosted tests launch ClipVee and watch the clipboard, so they run in CI only.
- Security investigation is separate. Flagged or binned copies are not touched.

## Evidence

- Owner manual check on an earlier installed head: preview text sizing works.
- `CardTextSizeTests` (in `MaccyTests`, run by CI) checks the 13 pt default, round-trips each size in a temporary preferences suite and falls back on an unknown value.
- Setup removal: signed local `build-for-testing` passes; no setup references remain.

## Open

- Push the setup removal to PR #10, then finish current-head CI and Codex review.
