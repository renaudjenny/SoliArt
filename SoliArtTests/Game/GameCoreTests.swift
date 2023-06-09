import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class GameCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store = TestStore(initialState: Game.State()) {
        Game()
    }
    private var cards: [Card] { cardsFromState(store.state) }

    func testShuffleCards() {
        shuffleCards()
    }

    func testDrawCard() {
        shuffleCards()

        store.send(.drawCard) {
            var facedUpCard = self.cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[29...])
        }

        store.send(.drawCard) {
            let facedUpCards = self.cards[28...29].map { card -> Card in
                var card = card
                card.isFacedUp = true
                return card
            }
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: facedUpCards)
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[30...])
        }
    }

    func testFlipDeck() {
        shuffleCards()

        for drawCardNumber in 28...51 {
            store.send(.drawCard) {
                let facedUpCards = self.cards[28...drawCardNumber].map { card -> Card in
                    var card = card
                    card.isFacedUp = true
                    return card
                }
                $0.deck.upwards = IdentifiedArrayOf(uniqueElements: facedUpCards)
                $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[(drawCardNumber + 1)...])
            }
        }

        store.send(.flipDeck) {
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[28...].map {
                var card = $0
                card.isFacedUp = false
                return card
            })
            $0.deck.upwards = []
        }

        store.send(.drawCard) {
            var facedUpCard = self.cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[29...])
        }
    }

    func testResetGame() {
        // TODO: do something that scores

        shuffleCards()

        store.send(.confirmResetGame) {
            $0.resetGameConfirmationDialog = .resetGame
        }

        store.send(.drawCard) {
            var facedUpCard = self.cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[29...])
        }

        store.send(.resetGame) {
            $0.resetGameConfirmationDialog = nil
            $0.isGameOver = true
        }

        store.receive(.shuffleCards) {
            $0.isGameOver = false
            $0.foundations = IdentifiedArrayOf(
                uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
            )
            $0.deck.upwards = []
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[28...])
            $0.deck.downwards[id: self.cards[28].id]?.isFacedUp = false
            $0.piles = Self.pilesAfterShuffle()
        }
    }

    static func pilesAfterShuffle() -> IdentifiedArrayOf<Pile> {
        IdentifiedArrayOf(uniqueElements: [
            Pile(id: 1, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.ace, of: .clubs, isFacedUp: true)
            ])),
            Pile(id: 2, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.two, of: .clubs, isFacedUp: false),
                StandardDeckCard(.three, of: .clubs, isFacedUp: true),
            ])),
            Pile(id: 3, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.four, of: .clubs, isFacedUp: false),
                StandardDeckCard(.five, of: .clubs, isFacedUp: false),
                StandardDeckCard(.six, of: .clubs, isFacedUp: true),
            ])),
            Pile(id: 4, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.seven, of: .clubs, isFacedUp: false),
                StandardDeckCard(.eight, of: .clubs, isFacedUp: false),
                StandardDeckCard(.nine, of: .clubs, isFacedUp: false),
                StandardDeckCard(.ten, of: .clubs, isFacedUp: true),
            ])),
            Pile(id: 5, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.jack, of: .clubs, isFacedUp: false),
                StandardDeckCard(.queen, of: .clubs, isFacedUp: false),
                StandardDeckCard(.king, of: .clubs, isFacedUp: false),
                StandardDeckCard(.ace, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.two, of: .diamonds, isFacedUp: true),
            ])),
            Pile(id: 6, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.three, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.four, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.five, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.six, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.seven, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.eight, of: .diamonds, isFacedUp: true),
            ])),
            Pile(id: 7, cards: IdentifiedArrayOf(uniqueElements: [
                StandardDeckCard(.nine, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.ten, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.jack, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.queen, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.king, of: .diamonds, isFacedUp: false),
                StandardDeckCard(.ace, of: .hearts, isFacedUp: false),
                StandardDeckCard(.two, of: .hearts, isFacedUp: true),
            ])),
        ])
    }

    static func pilesAfterShuffleForEasyGame() -> IdentifiedArrayOf<Pile> {
        var cards = [Card].easyFromTheDeck
        return IdentifiedArrayOf(uniqueElements: (1...7).map {
            var pile = Pile(id: $0, cards: IdentifiedArrayOf(uniqueElements: cards[..<$0]))
            cards = Array(cards[$0...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })
    }

    static func pilesAfterShuffleForEasyFromTheDeck() -> IdentifiedArrayOf<Pile> {
        var cards = [Card].easyFromTheDeck
        return IdentifiedArrayOf(uniqueElements: (1...7).map {
            var pile = Pile(id: $0, cards: IdentifiedArrayOf(uniqueElements: cards[..<$0]))
            cards = Array(cards[$0...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })
    }

    static func pilesAfterShuffleForSuperEasyGame() -> IdentifiedArrayOf<Pile> {
        var cards = Rank.allCases.flatMap { rank in
            Suit.allCases.map { suit in
                StandardDeckCard(rank, of: suit, isFacedUp: false)
            }
        }
        cards.swapAt(5, 1)
        cards.swapAt(9, 3)
        cards.swapAt(14, 1)
        cards.swapAt(20, 4)
        cards.swapAt(27, 6)
        return IdentifiedArrayOf(uniqueElements: (1...7).map {
            var pile = Pile(id: $0, cards: IdentifiedArrayOf(uniqueElements: cards[..<$0]))
            cards = Array(cards[$0...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })
    }

    private func shuffleCards(
        initialCards: [Card] = .standard52Deck,
        pilesAfterShuffle: IdentifiedArrayOf<Pile> = pilesAfterShuffle()
    ) {
        store.send(.shuffleCards) {
            $0.piles = pilesAfterShuffle
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: initialCards[28...])
            $0.isGameOver = false
        }
    }

    private func cardsFromState(_ state: Game.State) -> [Card] {
        state.piles.flatMap(\.cards)
            + state.foundations.flatMap(\.cards)
            + state.deck.upwards.elements
            + state.deck.downwards.elements
    }
}

private extension Array where Element == Card {
    static var easyFromTheDeck: Self {
        var cards = Rank.allCases.flatMap { rank in
            Suit.allCases.map { suit in
                StandardDeckCard(rank, of: suit, isFacedUp: false)
            }
        }
        cards.swapAt(0, 28)
        cards.swapAt(2, 29)
        return cards
    }
}
