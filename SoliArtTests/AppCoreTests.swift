import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class AppCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<AppState, AppState, AppAction, AppAction, AppEnvironment>!
    private var cards: [StandardDeckCard] { cardsFromState(store.state) }

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test(scheduler: scheduler))
    }

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

    func testDragCards() {
        shuffleCards()

        let state = DraggingState(card: cards[5], position: CGPoint(x: 123, y: 123))
        store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 3)
        }

        store.send(.dropCards) {
            $0.draggingState = nil
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: nil)
        }
    }


    func testUpdateFrame() {
        let frame: Frame = .pile(0, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrame(frame)) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }
    }

    func testDropCardsToAnOtherPile() {
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: .testEasyGame(scheduler: scheduler)
        )

        let frame: Frame = .pile(5, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrame(frame)) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

        shuffleCards(
            initialCards: AppEnvironment.superEasyGame.shuffleCards(),
            pilesAfterShuffle: Self.pilesAfterShuffleForEasyGame()
        )

        let dragCard = Card(.ace, of: .spades, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 123, y: 123))
        store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 4)
        }
        store.send(.dropCards) {
            $0.draggingState = nil
            var pile4 = $0.piles[id: 4]!
            pile4.cards.remove(dragCard)

            var threeOfClubs = pile4.cards[id: Card(.three, of: .clubs, isFacedUp: false).id]!
            threeOfClubs.isFacedUp = true
            pile4.cards.updateOrAppend(threeOfClubs)
            $0.piles.updateOrAppend(pile4)

            var pile5 = $0.piles[id: 5]!
            pile5.cards.updateOrAppend(dragCard)
            $0.piles.updateOrAppend(pile5)
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: nil)
        }
    }

    func testDropCardsToAFoundation() {
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: .testEasyGame(scheduler: scheduler)
        )

        let frame: Frame = .foundation(Suit.spades.id, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrame(frame)) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

        shuffleCards(
            initialCards: AppEnvironment.superEasyGame.shuffleCards(),
            pilesAfterShuffle: Self.pilesAfterShuffleForEasyGame()
        )

        let dragCard = Card(.ace, of: .spades, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 123, y: 123))
        store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 4)
        }

        store.send(.dropCards) {
            $0.draggingState = nil
            var pile4 = $0.piles[id: 4]!
            pile4.cards.remove(dragCard)

            var threeOfClubs = pile4.cards[id: Card(.three, of: .clubs, isFacedUp: false).id]!
            threeOfClubs.isFacedUp = true
            pile4.cards.updateOrAppend(threeOfClubs)
            $0.piles.updateOrAppend(pile4)

            var spadesFoundation = $0.foundations[id: Suit.spades.id]!
            spadesFoundation.cards.updateOrAppend(dragCard)
            $0.foundations.updateOrAppend(spadesFoundation)
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: nil)
        }
    }

    func testDragAndDropCardFromAFoundation() {
        testDropCardsToAFoundation()

        let frame: Frame = .pile(5, CGRect(x: 300, y: 300, width: 100, height: 200))
        store.send(.updateFrame(frame)) {
            $0.frames = IdentifiedArrayOf(uniqueElements: $0.frames + [frame])
        }

        let dragCard = Card(.ace, of: .spades, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 323, y: 323))
        store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .foundation(id: Suit.spades.id)
        }

        store.send(.dropCards) {
            $0.draggingState = nil
            var spadesFoundation = $0.foundations[id: Suit.spades.id]!
            spadesFoundation.cards.remove(dragCard)
            $0.foundations.updateOrAppend(spadesFoundation)

            var pile5 = $0.piles[id: 5]!
            pile5.cards.append(dragCard)
            $0.piles.updateOrAppend(pile5)
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: nil)
        }
    }

    func testResetGame() {
        testDropCardsToAFoundation()

        store.send(.promptResetGame) {
            $0.resetGameAlert = .resetGame
        }

        store.send(.drawCard) {
            var facedUpCard = self.cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[29...])
        }

        store.send(.resetGame) {
            $0.resetGameAlert = nil
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
            $0.piles = Self.pilesAfterShuffleForEasyGame()
        }
    }

    private func cardsFromState(_ state: AppState) -> [Card] {
        state.piles.flatMap(\.cards)
            + state.foundations.flatMap(\.cards)
            + state.deck.upwards.elements
            + state.deck.downwards.elements
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

    private static func pilesAfterShuffle() -> IdentifiedArrayOf<Pile> {
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

    private static func pilesAfterShuffleForEasyGame() -> IdentifiedArrayOf<Pile> {
        var cards = AppEnvironment.superEasyGame.shuffleCards()
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
}

extension AppEnvironment {
    static func test(scheduler: TestSchedulerOf<DispatchQueue>) -> AppEnvironment {
        AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(), shuffleCards: { .standard52Deck })
    }

    static func testEasyGame(scheduler: TestSchedulerOf<DispatchQueue>) -> AppEnvironment {
        AppEnvironment(
            mainQueue: scheduler.eraseToAnyScheduler(),
            shuffleCards: { AppEnvironment.superEasyGame.shuffleCards() }
        )
    }
}
