import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

@main
struct SoliArtApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: .superEasyGame
//                environment: AppEnvironment(
//                    mainQueue: .main,
//                    shuffleCards: { .standard52Deck.shuffled() }
//                )
            ))
        }
    }
}
