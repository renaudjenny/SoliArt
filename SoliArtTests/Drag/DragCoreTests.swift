import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class DragCoreTests: XCTestCase {
    private var store = TestStore(
        initialState: Drag.State(
            piles: GameCoreTests.pilesAfterShuffle(),
            foundations: Game.State().foundations
        )
    ) {
        Drag()
    }

    func testDragCards() {
        let scheduler = DispatchQueue.test
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        let state = DraggingState(card: Card(.six, of: .clubs, isFacedUp: true), position: CGPoint(x: 123, y: 123))
        store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 3)
        }

        store.send(.dropCards) {
            $0.draggingState = nil
        }

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }


    func testUpdateFrame() {
        let frame: Frame = .pile(0, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }
    }

    func testDropCardsToAnOtherPile() {
        let scheduler = DispatchQueue.test
        store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame()
            )
        ) {
            Drag()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }

        let frame: Frame = .pile(5, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

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

        store.receive(.delegate(.scoringMove(.turnOverPileCard)))

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDropCardsToAFoundation() {
        let scheduler = DispatchQueue.test
        store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }

        let frame: Frame = .foundation(Suit.spades.id, CGRect(x: 100, y: 100, width: 100, height: 200))
        store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

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

        store.receive(.delegate(.scoringMove(.moveToFoundation)))

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDragAndDropCardFromAFoundation() {
        let scheduler = DispatchQueue.test
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        testDropCardsToAFoundation()

        let frame: Frame = .pile(5, CGRect(x: 300, y: 300, width: 100, height: 200))
        let frames = IdentifiedArrayOf(uniqueElements: store.state.frames + [frame])
        store.send(.updateFrames(frames)) {
            $0.frames = frames
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

        store.receive(.delegate(.scoringMove(.moveBackFromFoundation)))

        scheduler.advance(by: 0.5)

        store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDoubleTapCardWithoutScoring() {
        let card = Card(.six, of: .clubs, isFacedUp: true)
        store.send(.doubleTapCard(card))
    }

    func testDoubleTapCardNotTheLastOneOfThePile() {
        // TODO: write a test to check that double tapping on card that is not the last one of the pile
        // won't go to the fondation
        let card = Card(.six, of: .clubs, isFacedUp: true)
        store.send(.doubleTapCard(card))
    }

    func testDoubleTapCardToScore() {
        let card = Card(.ace, of: .clubs, isFacedUp: true)
        store.send(.doubleTapCard(card)) {
            $0.foundations[id: Suit.clubs.rawValue]?.cards.append(card)
            $0.piles[id: 1]?.cards.remove(card)
        }
    }
}
