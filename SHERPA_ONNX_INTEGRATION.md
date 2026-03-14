# Sherpa-ONNX Integration

## Implemented app architecture
- `SpeechEngineType` adds explicit engine selection per speaker:
  - `sherpaOnnx`
  - `appleSystem`
- `SherpaOnnxEngine` is integrated in code as a dedicated runtime path.
- `DialogueReaderViewModel` routes playback by speaker engine.
- `SpeechPlaybackManager` supports both:
  - Apple utterance playback
  - File playback for sherpa-generated WAV

## Bundled model in this repo
- Logical default voice id: `en-us-default`
- Runtime voice list exposed via `SherpaOnnxEngine.bundledVoices`

## Current build behavior
- If Sherpa runtime/model is linked in build, sherpa path is used for speakers configured with `sherpaOnnx`.
- If not linked, app falls back to Apple TTS and shows a clear message.

## Enabling full sherpa runtime in Xcode
1. Add sherpa-onnx iOS framework/package.
2. Bundle TTS model files for selected sherpa voice(s).
3. Implement concrete sherpa API call in `SherpaOnnxEngine.synthesizeToWav`.
4. Validate generated WAV playback in app.

## App size/performance notes
- Local neural models can significantly increase app size.
- Latency depends on model and device.
