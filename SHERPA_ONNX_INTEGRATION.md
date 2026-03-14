# Sherpa-ONNX Integration Status

## Current build status
- A `SherpaOnnxEngine` scaffold file exists in the codebase.
- **Sherpa runtime and model assets are not linked in this repository build yet.**
- To avoid misleading UX, Sherpa is now hidden from speaker engine selection UI.
- App playback/export currently use Apple offline `AVSpeechSynthesizer` only.

## Why Sherpa is hidden
A selectable Sherpa option without linked runtime/models caused false expectations and fallback behavior. The app now shows an explicit status note in the speaker editor instead of a fake selectable path.

## What is needed for real Sherpa enablement
1. Link a real sherpa-onnx iOS runtime package/framework in Xcode.
2. Bundle at least one compatible local TTS model/voice.
3. Implement concrete synthesis in `SherpaOnnxEngine.synthesizeToWav`.
4. Re-enable Sherpa in `availableSpeechEngines` only when runtime+model checks pass.
