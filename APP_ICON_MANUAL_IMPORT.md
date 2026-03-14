# App Icon Manual Import

## Current status
The project currently uses the default Xcode AppIcon asset placeholder.

## Manual import steps
1. Prepare icon set in required iOS sizes (including 1024x1024 App Store icon).
2. Open `DialogueReader/Assets.xcassets/AppIcon.appiconset` in Xcode.
3. Drag and drop each icon to the matching size slot.
4. Ensure there are no empty required slots.
5. Build and verify icon appears on simulator/device home screen.

## Notes
- Keep source design files in a separate design folder (outside Xcode assets) for future updates.
- Re-check icon contrast in Light and Dark appearances.
