import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class HistoryCoreTests: XCTestCase {
    private var store: TestStore<HistoryState, HistoryState, HistoryAction, HistoryAction, HistoryEnvironment>!
    var now: () -> Date = { Date(timeIntervalSince1970: 0) }

    @MainActor override func setUp() async throws {
        store = TestStore(
            initialState: HistoryState(),
            reducer: historyReducer,
            environment: HistoryEnvironment(now: now)
        )
    }

    func testAddEntry() {
        let state = GameState()
        store.send(.addEntry(state)) {
            $0.entries = [HistoryEntry(date: self.now(), gameState: state)]
        }
    }
}
