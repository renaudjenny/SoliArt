import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

@main
struct SoliArtApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(
                initialState: .previewWithDrawnCards,
                reducer: appReducer,
                environment: AppEnvironment(
                    mainQueue: .main,
                    shuffleCards: { .standard52Deck.shuffled() },
                    now: Date.init
                )
            ))
        }
    }
}
