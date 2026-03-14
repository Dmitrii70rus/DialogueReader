# Local Offline TTS Engine Integration Notes (iOS MVP)

## What is implemented now
- Added a **real sherpa-onnx engine path in app architecture** (`SpeechEngineType.sherpaOnnx`).
- Added runtime engine wrapper (`SherpaOnnxEngine`) and per-speaker engine selection.
- Added playback manager support for file-based audio playback so sherpa-generated WAV output can be played.
- Kept Apple `AVSpeechSynthesizer` as fallback/secondary engine.

## Current status in this repository
- `SherpaOnnxEngine` is wired in code and selected per speaker.
- If sherpa runtime/model is not linked in build, app falls back to Apple voices with user-facing message.
- This keeps app stable and shippable while preserving a clean integration path.

## To enable sherpa synthesis in Xcode build
1. Add sherpa-onnx iOS package/framework to project.
2. Bundle required sherpa TTS model files for at least one voice.
3. Implement concrete `synthesizeToWav` binding in `SherpaOnnxEngine` for the package API version.
4. Verify generated WAV playback through `SpeechPlaybackManager.playAudioFile(url:)`.

## Why fallback remains
- Apple voices provide immediate offline reliability on all supported devices.
- sherpa model/runtime setup can vary per package version and model choice.

## App size/performance considerations
- Bundled local models increase app size.
- Neural/offline synthesis latency and power draw depend on model and device class.
