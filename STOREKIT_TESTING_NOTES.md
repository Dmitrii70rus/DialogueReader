# StoreKit Local Testing Notes

## Included configuration
- File: `DialogueReader/DialogueReader.storekit`
- Product type: Non-consumable
- Product ID: `dialoguereader.premium.unlock`
- Code constant must match: `PurchaseManager.premiumProductID`

## Xcode setup (required)
1. Open project in Xcode.
2. Select **Product → Scheme → Edit Scheme…**
3. Open **Run → Options**.
4. Set **StoreKit Configuration** to `DialogueReader.storekit`.
5. Run on iOS simulator.

## Recommended local test flows
1. Fresh launch: confirm paywall can load the premium product price.
2. Purchase flow: tap unlock and complete the local StoreKit transaction.
3. Verify entitlement: premium state removes the full-dialogue free limit gate.
4. Restore flow: tap **Restore Purchases** and verify premium state is restored.

## Resetting local transactions
- In simulator, open **Settings → Developer → StoreKit** and clear transactions if state is stale.
- If still stale, uninstall app and run again with StoreKit config attached.

## Common issues
- **Product unavailable**: Scheme is not attached to `.storekit` file.
- **Wrong product**: Product ID in `.storekit` does not exactly match `dialoguereader.premium.unlock`.
- **No entitlement update**: Ensure transaction finishes and relaunch app once.
