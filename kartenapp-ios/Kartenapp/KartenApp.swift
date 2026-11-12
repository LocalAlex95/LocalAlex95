import SwiftUI

@main
struct KartenApp: App {
    @State private var store = CardStore()

    var body: some Scene {
        WindowGroup {
            CardListView()
                .environment(store)
        }
    }
}
