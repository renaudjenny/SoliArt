import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class AppCoreTests: XCTestCase {
    private var store: TestStore = TestStore(initialState: App.State()) {
        App()
    } withDependencies: {
        $0.date = .constant(Date(timeIntervalSince1970: 0))
        $0.shuffleCards = ShuffleCards { .standard52Deck }
        $0.mainQueue = DispatchQueue.test.eraseToAnyScheduler()
    }
    private let now = Date(timeIntervalSince1970: 0)

    func testFlipDeck() {
        let historyEntry = HistoryEntry(date: now, gameState: Game.State(), scoreState: Score.State())
        store.send(.game(.flipDeck)) {
            $0.history.entries.append(historyEntry)
        }
    }

    func testFlipDeckWithScore() {
        store = TestStore(initialState: App.State(score: Score.State(score: 200))) {
            App()
        } withDependencies: {
            $0.date = .constant(self.now)
        }
        let historyEntry = HistoryEntry(
            date: now,
            gameState: Game.State(),
            scoreState: Score.State(score: 200)
        )
        store.send(.game(.flipDeck)) {
            $0.history.entries.append(historyEntry)
            $0.score.score = 100
        }
    }

    func testResetGame() {
        store.send(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score.score = 10
            $0.score.moves = 1
        }

        store.send(.game(.resetGame)) {
            $0.score = Score.State()
            $0.game = .withDispatchedCards
            $0.game.isGameOver = false
        }
    }

    func testGameActionThatUpdateState() {
        let afterShuffleHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: .withDispatchedCards,
            scoreState: Score.State()
        )
        store.send(.game(.shuffleCards)) {
            $0.game = .withDispatchedCards
            $0.history.entries = [afterShuffleHistoryEntry]
        }

        var gameStateAfterDrawingCard: Game.State = .withDispatchedCards
        var drawnCard = gameStateAfterDrawingCard.deck.downwards.removeFirst()
        drawnCard.isFacedUp = true
        gameStateAfterDrawingCard.deck.upwards = [drawnCard]
        let afterDrawingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDrawingCard,
            scoreState: Score.State()
        )
        store.send(.game(.drawCard)) {
            $0.game = gameStateAfterDrawingCard
            $0.history.entries.append(afterDrawingCardHistoryEntry)
        }

        var gameStateAfterDoubleTappingCard = gameStateAfterDrawingCard
        let aceOfClubs = Card(.ace, of: .clubs, isFacedUp: true)
        gameStateAfterDoubleTappingCard.foundations[id: Suit.clubs.rawValue]!.cards.append(aceOfClubs)
        gameStateAfterDoubleTappingCard.piles[id: 1]!.cards = []
        let scoreAfterDoubleTapping = Score.State(score: 10, moves: 1)
        let afterDoubleTappingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDoubleTappingCard,
            scoreState: Score.State()
        )
        store.send(.drag(.doubleTapCard(aceOfClubs))) {
            $0.game = gameStateAfterDoubleTappingCard
            $0.history.entries.append(afterDoubleTappingCardHistoryEntry)
        }
        store.receive(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score = scoreAfterDoubleTapping
        }

        var gameStateAfterDraggingCard = gameStateAfterDoubleTappingCard
        let draggedCard = Card(.two, of: .diamonds, isFacedUp: true)
        let frame = CGRect(x: 100, y: 100, width: 200, height: 400)
        store.send(.drag(.updateFrames([.pile(2, frame)]))) {
            $0.drag.frames.updateOrAppend(.pile(2, frame))
            $0.score = Score.State(score: 10, moves: 1)
        }
        let dropPosition = CGPoint(x: 110, y: 110)
        store.send(.drag(.dragCard(draggedCard, position: dropPosition))) {
            $0.drag.draggingState = DraggingState(card: draggedCard, position: dropPosition)
            $0.drag.zIndexPriority = .pile(id: 5)
        }
        gameStateAfterDraggingCard.piles[id: 5]!.cards.remove(draggedCard)
        var lastCardInPile = gameStateAfterDraggingCard.piles[id: 5]!.cards.last!
        lastCardInPile.isFacedUp = true
        gameStateAfterDraggingCard.piles[id: 5]!.cards.updateOrAppend(lastCardInPile)
        gameStateAfterDraggingCard.piles[id: 2]!.cards.append(draggedCard)
        let afterDraggingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDraggingCard,
            scoreState: Score.State(score: 10, moves: 1)
        )
        store.send(.drag(.dropCards)) {
            $0.drag.draggingState = nil
            $0.game = gameStateAfterDraggingCard
            $0.history.entries.append(afterDraggingCardHistoryEntry)
        }
        store.receive(.drag(.delegate(.scoringMove(.turnOverPileCard)))) {
            $0.score.score = 15
            $0.score.moves = 2
        }
    }

    func testHistoryUndo() {
        testGameActionThatUpdateState()

        store.send(.history(.undo)) {
            $0.history.entries.removeLast()
            $0.game = $0.history.entries.last!.gameState
            $0.score = Score.State(score: 0, moves: 0)
        }
    }

    func testAutoFinish() async {
        let aceOfSpades = Card(.ace, of: .spades, isFacedUp: true)
        var gameState = Game.State()
        gameState.piles[id: 1]?.cards.updateOrAppend(aceOfSpades)
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: App.State(game: gameState)) {
            App()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
            $0.mainQueue = scheduler.eraseToAnyScheduler()
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }
        let frame = CGRect(x: 10, y: 20, width: 100, height: 200)
        await store.send(.drag(.updateFrames([.foundation(Suit.spades.id, frame)]))) {
            $0.drag.frames.updateOrAppend(.foundation(Suit.spades.id, frame))
        }

        await store.send(.autoFinish(.checkForAutoFinish)) {
            $0.autoFinish.confirmationDialog = .autoFinish
        }

        await store.send(.autoFinish(.autoFinish)) {
            $0.autoFinish.confirmationDialog = nil
            $0.autoFinish.isAutoFinishing = true
        }

        let hint = HintMove(
            card: Card(.ace, of: .spades, isFacedUp: true),
            origin: .pile(id: 1),
            destination: .foundation(id: Suit.spades.id),
            position: .destination
        )

        let position = CGPoint(x: frame.midX, y: frame.midY)
        await store.receive(.drag(.dragCard(hint.card, position: position))) {
            $0.drag.draggingState = DraggingState(card: hint.card, position: position)
            $0.drag.zIndexPriority = .pile(id: 1)
        }
        var newGameState = gameState
        newGameState.foundations[id: Suit.spades.rawValue]?.cards = [aceOfSpades]
        newGameState.piles[id: 1]?.cards.removeAll()
        let historyEntry = HistoryEntry(date: self.now, gameState: newGameState, scoreState: store.state.score)
        await store.receive(.drag(.dropCards)) {
            $0.drag.draggingState = nil
            $0.game = newGameState
            $0.history.entries.append(historyEntry)
        }

        await store.receive(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score.score += 10
            $0.score.moves += 1
        }
    }
}

extension Game.State {
    static var withDispatchedCards: Self {
        Game.State(
            foundations: Game.State().foundations,
            piles: GameCoreTests.pilesAfterShuffle(),
            deck: Deck(
                downwards: IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...]),
                upwards: []
            ),
            isGameOver: false
        )
    }
}
