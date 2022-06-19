import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class AppCoreTests: XCTestCase {
    func testShuffleCards() {
        let store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test)
        let cards = [StandardDeckCard].standard52Deck(action: { _, _ in })

        store.send(.shuffleCards(cards)) {
            $0.piles = IdentifiedArrayOf(uniqueElements: [
                Pile(id: 1, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.ace, of: .clubs, isFacedUp: true)
                ])),
                Pile(id: 2, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.two, of: .clubs),
                    StandardDeckCard(.three, of: .clubs, isFacedUp: true),
                ])),
                Pile(id: 3, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.four, of: .clubs),
                    StandardDeckCard(.five, of: .clubs),
                    StandardDeckCard(.six, of: .clubs, isFacedUp: true),
                ])),
                Pile(id: 4, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.seven, of: .clubs),
                    StandardDeckCard(.eight, of: .clubs),
                    StandardDeckCard(.nine, of: .clubs),
                    StandardDeckCard(.ten, of: .clubs, isFacedUp: true),
                ])),
                Pile(id: 5, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.jack, of: .clubs),
                    StandardDeckCard(.queen, of: .clubs),
                    StandardDeckCard(.king, of: .clubs),
                    StandardDeckCard(.ace, of: .diamonds),
                    StandardDeckCard(.two, of: .diamonds, isFacedUp: true),
                ])),
                Pile(id: 6, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.three, of: .diamonds),
                    StandardDeckCard(.four, of: .diamonds),
                    StandardDeckCard(.five, of: .diamonds),
                    StandardDeckCard(.six, of: .diamonds),
                    StandardDeckCard(.seven, of: .diamonds),
                    StandardDeckCard(.eight, of: .diamonds, isFacedUp: true),
                ])),
                Pile(id: 7, cards: IdentifiedArrayOf(uniqueElements: [
                    StandardDeckCard(.nine, of: .diamonds),
                    StandardDeckCard(.ten, of: .diamonds),
                    StandardDeckCard(.jack, of: .diamonds),
                    StandardDeckCard(.queen, of: .diamonds),
                    StandardDeckCard(.king, of: .diamonds),
                    StandardDeckCard(.ace, of: .hearts),
                    StandardDeckCard(.two, of: .hearts, isFacedUp: true),
                ])),
            ])

            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }
    }
}

extension AppEnvironment {
    static let test = AppEnvironment(shuffleCards: { $0 })
}

private extension StandardDeckCard {
    init(_ rank: StandardDeckCard.Rank, of suit: StandardDeckCard.Suit, isFacedUp: Bool = false) {
        self.init(rank, of: suit, isFacedUp: isFacedUp, action: { })
    }
}
