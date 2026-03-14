# Voice Quality & Local TTS Limitations

DialogueReader is fully local/offline in MVP and uses Apple system voices via `AVSpeechSynthesizer`.

## How to get better Apple voices
Some high-quality voices are not preinstalled.

On iOS device:
1. Open **Settings**.
2. Go to **Accessibility → Spoken Content → Voices**.
3. Pick your language.
4. Download available **Enhanced** / **Premium** voices.

The app cannot download these voices automatically.

## Real limitations
- Voice inventory and quality vary by iOS version and device.
- Explicit male/female metadata is not guaranteed by Apple voice APIs.
- Fully local TTS is less expressive than cloud neural engines for some languages.
- Long text playback quality still depends on punctuation and input text formatting.
