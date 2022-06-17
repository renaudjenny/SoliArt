import ComposableArchitecture
import SwiftUI

@main
struct SoliArtApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppState(), reducer: appReducer, environment: AppEnvironment()))
        }
    }
}
