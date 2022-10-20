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
                foundations: GameState().foundations,
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
                foundations: GameState().foundations,
                piles: GameCoreTests.pilesAfterShuffleForEasyFromTheDeck(),
                deck: Deck(downwards: [], upwards: IdentifiedArrayOf(uniqueElements: [
                    Card(.ace, of: .clubs, isFacedUp: true)
                ]))
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

    func testConfirmationDialogAboutAutoFinish() {
        let almostFinishedGameState = AppState.almostFinishedGame.game
        store = TestStore(
            initialState: HintState(
                foundations: almostFinishedGameState.foundations,
                piles: almostFinishedGameState.piles,
                deck: almostFinishedGameState.deck
            ),
            reducer: hintReducer,
            environment: HintEnvironment(mainQueue: scheduler.eraseToAnyScheduler())
        )
        store.send(.checkForAutoFinish) {
            $0.autoFinishConfirmationDialog = .autoFinish
        }
    }

    func testConfirmationDialogAboutAutoFinishWhenItsNotPossibleToAutoFinish() {
        store = TestStore(
            initialState: HintState(
                foundations: GameState().foundations,
                piles: GameCoreTests.pilesAfterShuffle(),
                deck: Deck(downwards: [], upwards: [])
            ),
            reducer: hintReducer,
            environment: HintEnvironment(mainQueue: scheduler.eraseToAnyScheduler())
        )
        store.send(.checkForAutoFinish)
    }

    func testAutoFinish() {
        testConfirmationDialogAboutAutoFinish()

        store.send(.autoFinish) {
            $0.autoFinishConfirmationDialog = nil
            $0.isAutoFinishing = true
        }
    }
}
