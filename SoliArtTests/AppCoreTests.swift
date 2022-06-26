import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class AppCoreTests: XCTestCase {
    func testShuffleCards() {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test(scheduler: scheduler))
        let cards = [StandardDeckCard].standard52Deck

        store.send(.shuffleCards) {
            $0.piles = self.pilesAfterShuffle()
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }
    }

    func testDrawCard() {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test(scheduler: scheduler))
        let cards = [StandardDeckCard].standard52Deck

        store.send(.shuffleCards) {
            $0.piles = self.pilesAfterShuffle()
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }

        store.send(.drawCard) {
            var facedUpCard = cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[29...])
        }

        store.send(.drawCard) {
            var facedUpCard = cards[29]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [cards[28]] + [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[30...])
        }
    }

    func testFlipDeck() {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test(scheduler: scheduler))
        let cards = [StandardDeckCard].standard52Deck

        store.send(.shuffleCards) {
            $0.piles = self.pilesAfterShuffle()
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }

        for drawCardNumber in 28...51 {
            store.send(.drawCard) {
                var facedUpCard = cards[drawCardNumber]
                facedUpCard.isFacedUp = true
                $0.deck.upwards = IdentifiedArrayOf(uniqueElements: cards[28...drawCardNumber])
                $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[(drawCardNumber + 1)...])
            }
        }

        store.send(.flipDeck) {
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
            $0.deck.upwards = []
        }
        scheduler.advance(by: 0.4)
        store.receive(.drawCard) {
            var facedUpCard = cards[28]
            facedUpCard.isFacedUp = true
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[29...])
        }
    }

    func testDragCard() {
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: AppState(), reducer: appReducer, environment: .test(scheduler: scheduler))
        let cards = [StandardDeckCard].standard52Deck

        store.send(.shuffleCards) {
            $0.piles = self.pilesAfterShuffle()
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }

        let dragCard = DragCard(card: cards[42], position: CGPoint(x: 123, y: 123))
        store.send(.dragCard(dragCard)) {
            $0.draggedCard = dragCard
        }
    }

    private func pilesAfterShuffle() -> IdentifiedArrayOf<Pile> {
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
}

extension AppEnvironment {
    static func test(scheduler: TestSchedulerOf<DispatchQueue>) -> AppEnvironment {
        AppEnvironment(mainQueue: scheduler.eraseToAnyScheduler(), shuffleCards: { .standard52Deck })
    }
}

extension Card {
    init(_ rank: Rank, of suit: Suit, isFacedUp: Bool) {
        self.init(rank, of: suit, isFacedUp: isFacedUp) { CardBackground() }
    }
}
