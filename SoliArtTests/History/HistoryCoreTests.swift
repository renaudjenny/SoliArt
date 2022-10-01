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
            environment: HistoryEnvironment()
        )
    }

    func testAddEntry() {
        let entry = HistoryEntry(date: .now, gameState: GameState(), scoreState: ScoreState())
        store.send(.addEntry(entry)) {
            $0.entries = [entry]
        }
    }

    func testUndo() {
        testAddEntry()
        let firstEntry = store.state.entries.first!

        var gameState = GameState()
        gameState.foundations.append(Foundation(suit: .clubs, cards: [Card(.ace, of: .clubs, isFacedUp: true)]))
        gameState.piles.append(Pile(id: 1, cards: [Card(.two, of: .clubs, isFacedUp: true)]))
        let secondEntry = HistoryEntry(date: .now, gameState: gameState, scoreState: ScoreState(score: 15, moves: 2))

        store.send(.addEntry(secondEntry)) {
            $0.entries = [firstEntry, secondEntry]
        }

        store.send(.undo) {
            $0.entries = [firstEntry]
        }
    }
}
