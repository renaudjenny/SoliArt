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
                environment: AppEnvironment(
                    mainQueue: .main,
                    shuffleCards: AppEnvironment.superEasyGame.shuffleCards,
                    now: Date.init
                )
            ))
        }
    }
}
