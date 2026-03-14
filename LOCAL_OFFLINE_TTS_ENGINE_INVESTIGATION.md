# Local Offline TTS Engine Notes

## Implemented now
- Reliable offline Apple TTS path for playback.
- Real local export path to `.caf` audio using `AVSpeechSynthesizer.write`.
- Speaker-level voice/language/quality tuning persisted locally.

## Not yet implemented in this repo build
- Real Sherpa-ONNX runtime synthesis.
- Bundled Sherpa model assets.

## Product integrity rule applied
Sherpa is **not shown as selectable** unless runtime + model assets are actually linked. This avoids fake engine selection.

## Next concrete step
Integrate sherpa runtime and bundle model files, then enable engine selection conditionally based on runtime availability checks.
