# Local Offline TTS Engine Investigation (iOS MVP)

## Result
No third-party offline TTS engine was integrated in this iteration.

## Candidate reviewed
- **sherpa-onnx offline TTS (iOS)**

## sherpa-onnx feasibility summary
For this MVP release, sherpa-onnx is **not practical to integrate safely** without destabilizing app scope.

### Key concerns
1. **Bundle size impact**
   - Useful voices require shipping one or more ONNX models and token files.
   - This materially increases app binary/resources size.
2. **Runtime performance variability**
   - Low/mid devices can have high latency and higher battery usage for neural offline synthesis.
3. **Integration complexity**
   - Requires native wrapper integration, model lifecycle handling, and fallback logic alongside Apple TTS.
4. **Product maintenance burden**
   - Model versioning, QA matrix expansion, and long-term upgrade burden are high for current MVP scope.
5. **App Store shipping risk**
   - Increased complexity and asset footprint add review/quality risk without guaranteed UX win in this iteration.

## Decision
Use Apple-native offline speech as the production path for now:
- `AVSpeechSynthesizer`
- per-speaker voice/locale/rate/pitch/volume/pause settings
- quality-aware browsing (Standard/Enhanced/Premium)
- enhanced/premium preference where available

## Recommended next step (future)
If needed, prototype sherpa-onnx in a separate branch/spike with strict acceptance criteria:
- max bundle-size budget,
- acceptable P50/P95 latency on target devices,
- battery/perf threshold,
- clear fallback behavior to Apple voices.
