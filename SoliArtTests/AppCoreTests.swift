import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class AppCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<AppState, AppState, AppAction, AppAction, AppEnvironment>!

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(mainQueue: .main, shuffleCards: { [Card].standard52Deck })
        )
    }
}
