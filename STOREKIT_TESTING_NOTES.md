# StoreKit Local Testing Notes

## Included config
- File: `DialogueReader/DialogueReader.storekit`
- Product type: Non-consumable
- Product ID: `dialoguereader.premium.unlock`

## Xcode setup
1. Open the project in Xcode.
2. Select **Product > Scheme > Edit Scheme...**
3. Choose **Run > Options**.
4. Set **StoreKit Configuration** to `DialogueReader.storekit`.
5. Run the app on simulator.

## Recommended test flows
- Launch app and verify paywall loads product pricing.
- Complete purchase in StoreKit local environment.
- Confirm premium unlock removes full-dialogue session limit.
- Reinstall/reset and test **Restore Purchases**.

## Troubleshooting
- If product is unavailable, ensure the scheme has the `.storekit` file selected.
- If state appears stale, reset StoreKit transactions in simulator settings.
