import ComposableArchitecture
import SwiftUI
import SwiftUICardGame
import XCTestDynamicOverlay

@main
struct SoliArtApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            if !_XCTIsTesting {
                AppView(store: Store(initialState: App.State(), reducer: App()))
            }
        }
    }
}
