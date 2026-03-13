import SwiftUI

@main
struct DialogueReaderApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var speakerStore = SpeakerStore()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: DialogueReaderViewModel(purchaseManager: purchaseManager, speakerStore: speakerStore))
                .environmentObject(purchaseManager)
                .environmentObject(speakerStore)
                .task {
                    await purchaseManager.prepare()
                }
        }
    }
}
