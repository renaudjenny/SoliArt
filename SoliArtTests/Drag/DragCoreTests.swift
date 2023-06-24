import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class DragCoreTests: XCTestCase {
    func testDragCards() async {
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffle(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        }
        let scheduler = DispatchQueue.test
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        let state = DraggingState(card: Card(.six, of: .clubs, isFacedUp: true), position: CGPoint(x: 123, y: 123))
        await store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 3)
        }

        await store.send(.dropCards) {
            $0.draggingState = nil
        }

        await scheduler.advance(by: 0.5)

        await store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }


    func testUpdateFrame() async {
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffle(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        }
        let frame: Frame = .pile(0, CGRect(x: 100, y: 100, width: 100, height: 200))
        await store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }
    }

    func testDropCardsToAnOtherPile() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame()
            )
        ) {
            Drag()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }

        let frame: Frame = .pile(2, CGRect(x: 100, y: 100, width: 100, height: 200))
        await store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

        let dragCard = Card(.seven, of: .spades, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 123, y: 123))
        await store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 7)
        }
        await store.send(.dropCards) {
            $0.draggingState = nil

            $0.piles[id: 7]!.cards.remove(dragCard)

            $0.piles[id: 7]!.cards[id: Card(.seven, of: .hearts, isFacedUp: false).id]!.isFacedUp = true

            $0.piles[id: 2]!.cards.updateOrAppend(dragCard)
        }

        await store.receive(.delegate(.scoringMove(.turnOverPileCard)))

        await scheduler.advance(by: 0.5)

        await store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDropCardsToAFoundation() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }

        let frame: Frame = .foundation(Suit.diamonds.id, CGRect(x: 100, y: 100, width: 100, height: 200))
        await store.send(.updateFrames([frame])) {
            $0.frames = IdentifiedArrayOf(uniqueElements: [frame])
        }

        let dragCard = Card(.ace, of: .diamonds, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 123, y: 123))
        await store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .pile(id: 3)
        }

        await store.send(.dropCards) {
            $0.draggingState = nil

            $0.piles[id: 3]!.cards.remove(dragCard)

            $0.piles[id: 3]!.cards[id: Card(.two, of: .clubs, isFacedUp: false).id]!.isFacedUp = true

            $0.foundations[id: Suit.diamonds.id]!.cards.updateOrAppend(dragCard)
        }

        await store.receive(.delegate(.scoringMove(.moveToFoundation)))

        await scheduler.advance(by: 0.5)

        await store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDragAndDropCardFromAFoundation() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffleForEasyGame(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }
        await testDropCardsToAFoundation()

        let frame: Frame = .pile(5, CGRect(x: 300, y: 300, width: 100, height: 200))
        let frames = IdentifiedArrayOf(uniqueElements: store.state.frames + [frame])
        await store.send(.updateFrames(frames)) {
            $0.frames = frames
        }

        let dragCard = Card(.ace, of: .spades, isFacedUp: true)
        let state = DraggingState(card: dragCard, position: CGPoint(x: 323, y: 323))
        await store.send(.dragCard(state.card, position: state.position)) {
            $0.draggingState = state
            $0.zIndexPriority = .foundation(id: Suit.spades.id)
        }

        await store.send(.dropCards) {
            $0.draggingState = nil
            var spadesFoundation = $0.foundations[id: Suit.spades.id]!
            spadesFoundation.cards.remove(dragCard)
            $0.foundations.updateOrAppend(spadesFoundation)

            var pile5 = $0.piles[id: 5]!
            pile5.cards.append(dragCard)
            $0.piles.updateOrAppend(pile5)
        }

        await store.receive(.delegate(.scoringMove(.moveBackFromFoundation)))

        await scheduler.advance(by: 0.5)

        await store.receive(.resetZIndexPriority) {
            $0.zIndexPriority = .pile(id: 1)
        }
    }

    func testDoubleTapCardWithoutScoring() async {
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffle(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        }
        let card = Card(.six, of: .clubs, isFacedUp: true)
        await store.send(.doubleTapCard(card))
    }

    func testDoubleTapCardNotTheLastOneOfThePile() async {
        // TODO: write a test to check that double tapping on card that is not the last one of the pile
        // won't go to the fondation
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffle(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        }
        let card = Card(.six, of: .clubs, isFacedUp: true)
        await store.send(.doubleTapCard(card))
    }

    func testDoubleTapCardToScore() async {
        let store = TestStore(
            initialState: Drag.State(
                piles: GameCoreTests.pilesAfterShuffle(),
                foundations: Game.State().foundations
            )
        ) {
            Drag()
        }
        let card = Card(.ace, of: .clubs, isFacedUp: true)
        await store.send(.doubleTapCard(card)) {
            $0.foundations[id: Suit.clubs.rawValue]?.cards.append(card)
            $0.piles[id: 1]?.cards.remove(card)
        }
    }
}
