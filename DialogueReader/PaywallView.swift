import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Unlock DialogueReader Premium")
                    .font(.title2.bold())

                Text("Free users can run up to \(PurchaseManager.freePlayLimit) full-dialogue playback sessions after segmentation.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Unlimited full-dialogue playback sessions", systemImage: "infinity")
                    Label("All existing MVP features stay available", systemImage: "checkmark.circle")
                }
                .font(.subheadline)

                if let message = purchaseManager.storeMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if purchaseManager.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading Store…")
                        Spacer()
                    }
                } else {
                    Button {
                        Task {
                            await purchaseManager.purchasePremium()
                            if purchaseManager.isPremiumUnlocked {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(unlockButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(purchaseManager.product == nil)

                    Button("Restore Purchases") {
                        Task {
                            await purchaseManager.restorePurchases()
                            if purchaseManager.isPremiumUnlocked {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    if purchaseManager.product == nil {
                        Text("Store unavailable in current configuration.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var unlockButtonTitle: String {
        guard let product = purchaseManager.product else {
            return "Unlock Premium"
        }
        return "Unlock Premium – \(product.displayPrice)"
    }
}
