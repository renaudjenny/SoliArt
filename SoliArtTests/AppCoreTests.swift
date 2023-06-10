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
        store.send(.score(.score(.moveToFoundation))) {
            $0.score.score = 10
            $0.score.moves = 1
        }

        store.send(.game(.resetGame)) {
            $0.score = Score.State()
            $0.game = .stateWithDispatchedCards(.standard52Deck)
            $0.game.isGameOver = false
        }
    }

    func testGameActionThatUpdateState() {
        let gameStateAfterShuffle = Game.State(
            foundations: Game.State().foundations,
            piles: GameCoreTests.pilesAfterShuffle(),
            deck: Deck(
                downwards: IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...]),
                upwards: []
            ),
            isGameOver: false
        )
        store.send(.game(.shuffleCards)) {
            $0.game = gameStateAfterShuffle
        }
        let afterShuffleHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterShuffle,
            scoreState: Score.State()
        )
        store.receive(.history(.addEntry(afterShuffleHistoryEntry))) {
            $0.history.entries = [afterShuffleHistoryEntry]
        }

        var gameStateAfterDrawingCard = gameStateAfterShuffle
        var drawnCard = gameStateAfterDrawingCard.deck.downwards.removeFirst()
        drawnCard.isFacedUp = true
        gameStateAfterDrawingCard.deck.upwards = [drawnCard]
        store.send(.game(.drawCard)) {
            $0.game = gameStateAfterDrawingCard
        }
        let afterDrawingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDrawingCard,
            scoreState: Score.State()
        )
        store.receive(.history(.addEntry(afterDrawingCardHistoryEntry))) {
            $0.history.entries.append(afterDrawingCardHistoryEntry)
        }

        var gameStateAfterDoubleTappingCard = gameStateAfterDrawingCard
        let aceOfClubs = Card(.ace, of: .clubs, isFacedUp: true)
        gameStateAfterDoubleTappingCard.foundations[id: Suit.clubs.rawValue]!.cards.append(aceOfClubs)
        gameStateAfterDoubleTappingCard.piles[id: 1]!.cards = []
        store.send(.drag(.doubleTapCard(aceOfClubs))) {
            $0.game = gameStateAfterDoubleTappingCard
        }
        store.receive(.drag(.score(.score(.moveToFoundation))))
        let afterDoubleTappingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDoubleTappingCard,
            scoreState: Score.State()
        )
        store.receive(.history(.addEntry(afterDoubleTappingCardHistoryEntry))) {
            $0.history.entries.append(afterDoubleTappingCardHistoryEntry)
        }
        store.receive(.score(.score(.moveToFoundation))) {
            $0.score.score = 10
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 1
        }

        var gameStateAfterDraggingCard = gameStateAfterDoubleTappingCard
        let draggedCard = Card(.two, of: .diamonds, isFacedUp: true)
        let frame = CGRect(x: 100, y: 100, width: 200, height: 400)
        store.send(.drag(.updateFrames([.pile(2, frame)]))) {
            $0.drag.frames.updateOrAppend(.pile(2, frame))
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
        store.send(.drag(.dropCards)) {
            $0.drag.draggingState = nil
            $0.game = gameStateAfterDraggingCard
        }
        store.receive(.drag(.score(.score(.turnOverPileCard))))
        let afterDraggingCardHistoryEntry = HistoryEntry(
            date: self.now,
            gameState: gameStateAfterDraggingCard,
            scoreState: Score.State(score: 10, moves: 1)
        )
        store.receive(.history(.addEntry(afterDraggingCardHistoryEntry))) {
            $0.history.entries.append(afterDraggingCardHistoryEntry)
        }
        store.receive(.score(.score(.turnOverPileCard))) {
            $0.score.score = 15
        }
        store.receive(.score(.incrementMove)) {
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
        var foundations = Game.State().foundations
        let spadesFoundation = Foundation(suit: .spades, cards: [Card(.ace, of: .spades, isFacedUp: true)])
        foundations.updateOrAppend(spadesFoundation)
        let scheduler = DispatchQueue.test
        store = TestStore(
            initialState: App.State(
                game: Game.State(foundations: foundations),
                _autoFinish: AutoFinish.State(isAutoFinishing: true)
            )
        ) {
            App()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }
        let frame = CGRect(x: 10, y: 20, width: 100, height: 200)
        _ = await store.send(.drag(.updateFrames([.foundation(Suit.spades.id, frame)]))) {
            $0.drag.frames.updateOrAppend(.foundation(Suit.spades.id, frame))
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
            $0.drag.zIndexPriority = .foundation(id: Suit.spades.id)
        }
        await store.receive(.drag(.dropCards)) {
            $0.drag.draggingState = nil
        }
        await scheduler.advance(by: 0.2)
        let historyEntry = HistoryEntry(date: self.now, gameState: store.state.game, scoreState: store.state.score)
        await store.receive(.history(.addEntry(historyEntry))) {
            $0.history.entries.append(historyEntry)
        }
        _ = await store.send(.autoFinish(.checkForAutoFinish))
        await store.receive(.autoFinish(.autoFinish))
    }
}

extension Game.State {
    static func stateWithDispatchedCards(_ cards: [Card]) -> Self {
        var state = Game.State()
        var cards = cards
        state.piles = IdentifiedArrayOf(uniqueElements: (1...7).map {
            var pile = Pile(id: $0, cards: [])
            pile.cards = IdentifiedArrayOf(uniqueElements: cards[..<$0])
            cards = Array(cards[$0...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })

        state.deck.upwards = []
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards)

        state.foundations = IdentifiedArrayOf(
            uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
        )
        return state
    }
}
