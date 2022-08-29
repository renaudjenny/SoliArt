import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class DragCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<DragState, DragState, DragAction, DragAction, DragEnvironment>!

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(
            initialState: DragState(),
            reducer: dragReducer,
            environment: DragEnvironment(mainQueue: .main)
        )
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

        store.receive(.score(.score(.turnOverPileCard))) {
            $0.score.score = 5
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 1
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

        store.receive(.score(.score(.moveToFoundation))) {
            $0.score.score = 10
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 1
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

        store.receive(.score(.score(.moveBackFromFoundation))) {
            $0.score.score = 0
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 2
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: nil)
        }
    }

    func testDoubleTapCardWithoutScoring() {
        shuffleCards()

        let card = Card(.six, of: .clubs, isFacedUp: true)
        store.send(.doubleTapCard(card))
    }

    func testDoubleTapCardToScore() {
        shuffleCards()

        let card = Card(.ace, of: .clubs, isFacedUp: true)
        store.send(.doubleTapCard(card)) {
            $0.foundations[id: Suit.clubs.rawValue]?.cards.append(card)
            $0.piles[id: 1]?.cards.remove(card)
        }
    }
}
