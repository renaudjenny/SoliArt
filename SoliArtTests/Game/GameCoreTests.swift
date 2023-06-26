import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class GameCoreTests: XCTestCase {
    func testShuffleCards() async {
        let store = TestStore(initialState: Game.State()) {
            Game()
        } withDependencies: {
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }

        await store.send(.shuffleCards) {
            $0.piles = .standard
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...])
            $0.isGameOver = false
        }
    }

    func testDrawCard() {
        let store = TestStore(initialState: Game.State()) {
            Game()
        } withDependencies: {
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }

        store.send(.shuffleCards) {
            $0.piles = .standard
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...])
            $0.isGameOver = false
        }

        store.send(.drawCard) {
            var facedUpCard = [Card].standard52Deck[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[29...])
        }

        store.send(.drawCard) {
            let facedUpCards = [Card].standard52Deck[28...29].map { card -> Card in
                var card = card
                card.isFacedUp = true
                return card
            }
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: facedUpCards)
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[30...])
        }
    }

    func testFlipDeck() {
        let store = TestStore(initialState: Game.State()) {
            Game()
        } withDependencies: {
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }

        store.send(.shuffleCards) {
            $0.piles = .standard
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...])
            $0.isGameOver = false
        }

        for drawCardNumber in 28...51 {
            store.send(.drawCard) {
                let facedUpCards = [Card].standard52Deck[28...drawCardNumber].map { card -> Card in
                    var card = card
                    card.isFacedUp = true
                    return card
                }
                $0.deck.upwards = IdentifiedArrayOf(uniqueElements: facedUpCards)
                $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[(drawCardNumber + 1)...])
            }
        }

        store.send(.flipDeck) {
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...].map {
                var card = $0
                card.isFacedUp = false
                return card
            })
            $0.deck.upwards = []
        }

        store.send(.drawCard) {
            var facedUpCard = [Card].standard52Deck[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[29...])
        }
    }
}
