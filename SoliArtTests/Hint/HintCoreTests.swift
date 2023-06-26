import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class HintCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store = TestStore(
        initialState: Hint.State(
            foundations: Game.State().foundations,
            piles: .easyGame
        )
    ) {
        Hint()
    }

    func testHintToMoveFromPileToFoundation() {
        store.send(.hint) {
            $0.hint = HintMove(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .pile(id: 1),
                destination: .foundation(id: Suit.clubs.rawValue),
                position: .source
            )
        }
    }

    func testHintToMoveFromDeckToFoundation() {
        store = TestStore(
            initialState: Hint.State(
                foundations: Game.State().foundations,
                piles: .easyGame,
                deck: Deck(downwards: [], upwards: IdentifiedArrayOf(uniqueElements: [
                    Card(.ace, of: .clubs, isFacedUp: true)
                ]))
            )
        ) {
            Hint()
        }

        store.send(.hint) {
            $0.hint = HintMove(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .deck,
                destination: .foundation(id: Suit.clubs.rawValue),
                position: .source
            )
        }
    }

    // FIXME: Autofinish tests should be moved to their own file and use their own reducer

    func testConfirmationDialogAboutAutoFinish() {
        let almostFinishedGameState = App.State.almostFinishedGame.game
        store = TestStore(
            initialState: Hint.State(
                foundations: almostFinishedGameState.foundations,
                piles: almostFinishedGameState.piles,
                deck: almostFinishedGameState.deck
            )
        ) {
            Hint()
        }

        XCTFail("Autofinish tests should be moved to their own file and use their own reducer")
//        store.send(.checkForAutoFinish) {
//            $0.autoFinishConfirmationDialog = .autoFinish
//        }
    }

    func testConfirmationDialogAboutAutoFinishWhenItsNotPossibleToAutoFinish() {
        store = TestStore(
            initialState: Hint.State(
                foundations: Game.State().foundations,
                piles: .standard,
                deck: Deck(downwards: [], upwards: [])
            )
        ) {
            Hint()
        }
        XCTFail("Autofinish tests should be moved to their own file and use their own reducer")
//        store.send(.checkForAutoFinish)
    }
}
