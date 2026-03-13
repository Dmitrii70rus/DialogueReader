# Local Offline TTS Engine Investigation (iOS MVP)

## Result
No third-party offline TTS engine was integrated in this iteration.

## Why
For this MVP and App Store-safe scope, native Apple speech APIs remain the most practical option:
- Already available on iOS with no extra runtime dependencies.
- Better long-term maintainability for a lightweight SwiftUI app.
- Easier legal/compliance posture vs. embedding large third-party voice models.

## Investigated direction
We evaluated whether adding a free local/offline TTS library would be realistic for this release criteria. Main blockers for MVP quality and maintainability:
- Package size impact from bundled models.
- Device performance variability and battery cost.
- Integration complexity with SwiftUI + iOS release process.
- Voice quality gains are uncertain without substantial model/runtime tuning.

## Decision
Keep the app native-first on `AVSpeechSynthesizer` and improve quality via:
- enhanced voice preference when available,
- per-speaker language/voice/rate/pitch/pause/volume,
- dedicated speaker profile management and persistence.
