import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class HintCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<HintState, HintState, HintAction, HintAction, HintEnvironment>!

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(
            initialState: HintState(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame()
            ),
            reducer: hintReducer,
            environment: HintEnvironment(mainQueue: scheduler.eraseToAnyScheduler())
        )
    }

    func testHintToMoveFromPileToFoundation() {
        store.send(.hint) {
            $0.hint = Hint(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .pile(id: 1),
                destination: .foundation(id: Suit.clubs.rawValue),
                position: .source
            )
        }
    }

    func testHintToMoveFromDeckToFoundation() {
        store = TestStore(
            initialState: HintState(
                piles: GameCoreTests.pilesAfterShuffleForEasyFromTheDeck(),
                deckUpwards: IdentifiedArrayOf(uniqueElements: [
                    Card(.ace, of: .clubs, isFacedUp: true)
                ])
            ),
            reducer: hintReducer,
            environment: HintEnvironment(mainQueue: scheduler.eraseToAnyScheduler())
        )

        store.send(.hint) {
            $0.hint = Hint(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .deck,
                destination: .foundation(id: Suit.clubs.rawValue),
                position: .source
            )
        }
    }
}
