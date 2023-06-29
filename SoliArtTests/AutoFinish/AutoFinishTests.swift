import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class AutoFinishTests: XCTestCase {
    func testCheckForAutoFinish() async {
        let store = TestStore(
            initialState: AutoFinish.State(
                foundations: .standard,
                piles: .standard,
                deck: .standard,
                nextHint: .firstForStandard
            )
        ) {
            AutoFinish()
        }

        await store.send(.checkForAutoFinish)
    }

    func testCheckForPositiveAutoFinish() async {
        let piles = IdentifiedArray(uniqueElements: [
            Pile(id: 1, cards: [Card(.ace, of: .clubs, isFacedUp: true)]),
            Pile(id: 2, cards: [Card(.ace, of: .diamonds, isFacedUp: true)]),
            Pile(id: 3, cards: [Card(.ace, of: .hearts, isFacedUp: true)]),
            Pile(id: 4, cards: [Card(.ace, of: .spades, isFacedUp: true)]),
            Pile(id: 5, cards: [Card(.two, of: .clubs, isFacedUp: true)]),
            Pile(id: 6, cards: [Card(.two, of: .diamonds, isFacedUp: true)]),
            Pile(id: 7, cards: [Card(.two, of: .hearts, isFacedUp: true)]),
        ])
        let store = TestStore(
            initialState: AutoFinish.State(
                foundations: .standard,
                piles: piles,
                deck: .standard,
                nextHint: .firstForStandard
            )
        ) {
            AutoFinish()
        }

        await store.send(.checkForAutoFinish) {
            $0.confirmationDialog = .autoFinish
        }
    }
}

extension HintMove {
    static var firstForStandard: Self {
        HintMove(
            card: Card(.ace, of: .clubs, isFacedUp: true),
            origin: .pile(id: 1),
            destination: .foundation(id: Suit.clubs.rawValue),
            position: .source
        )
    }
}
