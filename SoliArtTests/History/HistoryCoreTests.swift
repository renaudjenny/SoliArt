import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class HistoryCoreTests: XCTestCase {
    private var store: TestStore<HistoryState, HistoryState, HistoryAction, HistoryAction, HistoryEnvironment>!

    @MainActor override func setUp() async throws {
        store = TestStore(
            initialState: HistoryState(),
            reducer: historyReducer,
            environment: HistoryEnvironment(now: { Date(timeIntervalSince1970: 0) })
        )
    }

    func testAddEntry() {
        let state = GameState()
        let now = store.environment.now()
        store.send(.addEntry(state)) {
            $0.entries = [HistoryEntry(date: now, gameState: state)]
        }
    }

    func testUndo() {
        testAddEntry()

        var state2 = GameState()
        state2.foundations.append(Foundation(suit: .clubs, cards: [Card(.ace, of: .clubs, isFacedUp: true)]))
        state2.piles.append(Pile(id: 1, cards: [Card(.two, of: .clubs, isFacedUp: true)]))

        let date = Date(timeIntervalSince1970: 60)
        store.environment.now = { date }

        store.send(.addEntry(state2)) {
            $0.entries += [HistoryEntry(date: date, gameState: state2)]
        }

        store.send(.undo) {
            $0.entries = [self.store.state.entries.first!]
        }
    }
}
