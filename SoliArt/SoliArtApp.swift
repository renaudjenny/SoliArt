import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

@main
struct SoliArtApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: .autoFinishAvailable, reducer: App()))
        }
    }
}
