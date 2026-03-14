# Local Offline TTS Engine Notes

## Current app architecture
- Primary engine in UI: **Natural Offline Voice (Recommended)**.
- Fallback engine: Apple system voice.
- `TTSModelManager` scans bundled neural model files from `Models/TTS/`.

## Why fallback is currently active
- sherpa runtime is not linked in the current repository build.
- neural model assets are not currently present in the app bundle.
- fallback to Apple is automatic to keep playback/export functional.

## Next integration step
1. Add sherpa iOS package/framework.
2. Bundle at least 2 neural model pairs (`.onnx` + `.tokens`) under `Models/TTS/`.
3. Wire `SherpaOnnxEngine.synthesizeToWav` to real sherpa API.
4. Validate preview/dialogue/export with neural voices.
