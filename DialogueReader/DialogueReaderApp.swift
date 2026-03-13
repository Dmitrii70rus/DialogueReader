import SwiftUI

@main
struct DialogueReaderApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchaseManager))
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.prepare()
                }
        }
    }
}
