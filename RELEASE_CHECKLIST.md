# DialogueReader Release Checklist

## Product & UX
- [ ] Verify the text editor accepts long-form pasted text.
- [ ] Confirm splitting uses one non-empty line per segment.
- [ ] Validate speaker assignment per segment works.
- [ ] Confirm single-segment playback works.
- [ ] Confirm full-dialogue playback works.
- [ ] Validate empty states and user-friendly guidance.
- [ ] Confirm error messaging for empty text and unavailable voices.

## Monetization
- [ ] Validate free limit (3 full-dialogue sessions) for non-premium users.
- [ ] Confirm paywall appears when limit is reached.
- [ ] Confirm purchase flow for `dialoguereader.premium.unlock`.
- [ ] Confirm restore purchases flow updates unlock state.

## StoreKit
- [ ] Ensure `DialogueReader.storekit` is selected in Xcode Run scheme for local tests.
- [ ] Validate product metadata and pricing display in paywall.

## Technical
- [ ] Run on latest iOS simulator (17+ target behavior).
- [ ] Test on physical device for voice availability differences.
- [ ] Validate app launch, background/foreground behavior, and playback stop.
- [ ] Validate no crashes in basic happy-path and edge-path interactions.

## App Store Prep
- [ ] Finalize metadata copy and URLs.
- [ ] Import final app icon assets.
- [ ] Capture App Store screenshots.
- [ ] Confirm legal/compliance and privacy responses in App Store Connect.
