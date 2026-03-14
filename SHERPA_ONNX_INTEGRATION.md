# Sherpa-ONNX Integration Status

## Implemented architecture
- Added `TTSModelManager` for neural model catalog/loading from bundle path `Models/TTS/`.
- Added neural voice catalog entries:
  - `female-natural`
  - `male-natural`
  - `female-warm`
  - `male-deep`
- Speaker configuration now presents **Natural Offline Voice (Recommended)** as primary engine and Apple as fallback.
- `DialogueReaderViewModel` routes playback to Sherpa first when neural models and runtime are available.

## Current blocker in this repo build
- The environment cannot fetch/link sherpa binaries from GitHub (network tunnel to GitHub returns 403).
- No actual `.onnx` + `.tokens` neural model files are bundled in this repository yet.
- Therefore this build still falls back to Apple runtime playback.

## Required model file structure
Place bundled files in app target:
- `Models/TTS/female-natural.onnx`
- `Models/TTS/female-natural.tokens`
- `Models/TTS/male-natural.onnx`
- `Models/TTS/male-natural.tokens`
- `Models/TTS/female-warm.onnx`
- `Models/TTS/female-warm.tokens`
- `Models/TTS/male-deep.onnx`
- `Models/TTS/male-deep.tokens`

## Remaining step for real synthesis
Implement concrete sherpa synthesis call in `SherpaOnnxEngine.synthesizeToWav` once sherpa package+models are linked in Xcode.
