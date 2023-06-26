import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class AppCoreTests: XCTestCase {
    func testFlipDeck() {
        let now = Date(timeIntervalSince1970: 0)
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.date = .constant(now)
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }
        let historyEntry = HistoryEntry(date: now, gameState: Game.State(), scoreState: Score.State())
        store.send(.game(.flipDeck)) {
            $0.history.entries.append(historyEntry)
        }
    }

    func testFlipDeckWithScore() {
        let now = Date(timeIntervalSince1970: 0)
        let store = TestStore(initialState: App.State(score: Score.State(score: 200))) {
            App()
        } withDependencies: {
            $0.date = .constant(now)
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
        let store = TestStore(initialState: App.State(score: Score.State(score: 200))) {
            App()
        } withDependencies: {
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }
        store.send(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score.score = 210
            $0.score.moves = 1
        }

        store.send(.game(.resetGame)) {
            $0.score = Score.State()
            $0.game = .withDispatchedCards
            $0.game.isGameOver = false
        }
    }

    func testGameActionThatUpdateState() async {
        let now = Date(timeIntervalSince1970: 0)
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.date = .constant(now)
            $0.shuffleCards = ShuffleCards { .standard52Deck }
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }
        let afterShuffleHistoryEntry = HistoryEntry(
            date: now,
            gameState: .withDispatchedCards,
            scoreState: Score.State()
        )
        await store.send(.game(.shuffleCards)) {
            $0.game = .withDispatchedCards
            $0.history.entries = [afterShuffleHistoryEntry]
        }

        var gameStateAfterDrawingCard: Game.State = .withDispatchedCards
        var drawnCard = gameStateAfterDrawingCard.deck.downwards.removeFirst()
        drawnCard.isFacedUp = true
        gameStateAfterDrawingCard.deck.upwards = [drawnCard]
        let afterDrawingCardHistoryEntry = HistoryEntry(
            date: now,
            gameState: gameStateAfterDrawingCard,
            scoreState: Score.State()
        )
        await store.send(.game(.drawCard)) {
            $0.game = gameStateAfterDrawingCard
            $0.history.entries.append(afterDrawingCardHistoryEntry)
        }

        var gameStateAfterDoubleTappingCard = gameStateAfterDrawingCard
        let aceOfClubs = Card(.ace, of: .clubs, isFacedUp: true)
        gameStateAfterDoubleTappingCard.foundations[id: Suit.clubs.rawValue]!.cards.append(aceOfClubs)
        gameStateAfterDoubleTappingCard.piles[id: 1]!.cards = []
        let scoreAfterDoubleTapping = Score.State(score: 10, moves: 1)
        let afterDoubleTappingCardHistoryEntry = HistoryEntry(
            date: now,
            gameState: gameStateAfterDoubleTappingCard,
            scoreState: Score.State()
        )
        await store.send(.drag(.doubleTapCard(aceOfClubs))) {
            $0.game = gameStateAfterDoubleTappingCard
            $0.history.entries.append(afterDoubleTappingCardHistoryEntry)
        }
        await store.receive(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score = scoreAfterDoubleTapping
        }

        var gameStateAfterDraggingCard = gameStateAfterDoubleTappingCard
        let draggedCard = Card(.two, of: .diamonds, isFacedUp: true)
        let frame = CGRect(x: 100, y: 100, width: 200, height: 400)
        await store.send(.drag(.updateFrames([.pile(2, frame)]))) {
            $0.drag.frames.updateOrAppend(.pile(2, frame))
            $0.score = Score.State(score: 10, moves: 1)
        }
        let dropPosition = CGPoint(x: 110, y: 110)
        await store.send(.drag(.dragCard(draggedCard, position: dropPosition))) {
            $0.drag.draggingState = DraggingState(card: draggedCard, position: dropPosition)
            $0.drag.zIndexPriority = .pile(id: 5)
        }
        gameStateAfterDraggingCard.piles[id: 5]!.cards.remove(draggedCard)
        var lastCardInPile = gameStateAfterDraggingCard.piles[id: 5]!.cards.last!
        lastCardInPile.isFacedUp = true
        gameStateAfterDraggingCard.piles[id: 5]!.cards.updateOrAppend(lastCardInPile)
        gameStateAfterDraggingCard.piles[id: 2]!.cards.append(draggedCard)
        let afterDraggingCardHistoryEntry = HistoryEntry(
            date: now,
            gameState: gameStateAfterDraggingCard,
            scoreState: Score.State(score: 10, moves: 1)
        )
        await store.send(.drag(.dropCards)) {
            $0.drag.draggingState = nil
            $0.game = gameStateAfterDraggingCard
            $0.history.entries.append(afterDraggingCardHistoryEntry)
        }
        await scheduler.advance(by: .seconds(0.5))
        await store.receive(.drag(.delegate(.scoringMove(.turnOverPileCard)))) {
            $0.score.score = 15
            $0.score.moves = 2
        }
        await store.receive(.drag(.resetZIndexPriority)) {
            $0.drag.zIndexPriority = .pile(id: 1)
        }
    }

    func testHistoryUndo() {
        let now = Date(timeIntervalSince1970: 0)
        let store = TestStore(
            initialState: App.State(
                history: History.State(
                    entries: [
                        HistoryEntry(
                            date: now,
                            gameState: .withDispatchedCards,
                            scoreState: Score.State(score: 0, moves: 1)
                        ),
                        HistoryEntry(
                            date: now,
                            gameState: .previewWithDrawnCards,
                            scoreState: Score.State(score: 10, moves: 2)
                        )
                    ]
                )
            )
        ) {
            App()
        }
        store.send(.history(.undo)) {
            $0.history.entries.removeLast()
            $0.game = .withDispatchedCards
            $0.score = Score.State(score: 0, moves: 1)
        }
    }

    func testAutoFinish() async {
        let now = Date(timeIntervalSince1970: 0)
        let aceOfSpades = Card(.ace, of: .spades, isFacedUp: true)
        var gameState = Game.State()
        gameState.piles[id: 1]?.cards.updateOrAppend(aceOfSpades)
        let scheduler = DispatchQueue.test
        let store = TestStore(initialState: App.State(game: gameState)) {
            App()
        } withDependencies: {
            $0.date = .constant(now)
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

        let hint = HintMove(
            card: Card(.ace, of: .spades, isFacedUp: true),
            origin: .pile(id: 1),
            destination: .foundation(id: Suit.spades.id),
            position: .destination
        )

        let position = CGPoint(x: frame.midX, y: frame.midY)

        var newGameState = gameState
        newGameState.foundations[id: Suit.spades.rawValue]?.cards = [aceOfSpades]
        newGameState.piles[id: 1]?.cards.removeAll()
        let historyEntry = HistoryEntry(date: now, gameState: newGameState, scoreState: store.state.score)

        await store.send(.autoFinish(.autoFinish)) {
            $0.autoFinish.confirmationDialog = nil
            $0.autoFinish.isAutoFinishing = true
        }

        await store.receive(.drag(.dragCard(hint.card, position: position))) {
            $0.drag.draggingState = DraggingState(card: hint.card, position: position)
            $0.drag.zIndexPriority = .pile(id: 1)
        }
        await store.receive(.drag(.dropCards)) {
            $0.drag.draggingState = nil
            $0.game = newGameState
            $0.history.entries.append(historyEntry)
        }
        await scheduler.advance(by: .seconds(0.5))
        await store.receive(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score.score += 10
            $0.score.moves += 1
        }
        await store.receive(.autoFinish(.autoFinish)) {
            $0.autoFinish.isAutoFinishing = false
        }
        await store.receive(.drag(.resetZIndexPriority))
    }
}

extension Game.State {
    static var withDispatchedCards: Self {
        Game.State(
            foundations: Game.State().foundations,
            piles: .standard,
            deck: Deck(
                downwards: IdentifiedArrayOf(uniqueElements: [Card].standard52Deck[28...]),
                upwards: []
            ),
            isGameOver: false
        )
    }
}

extension IdentifiedArray<Int, Pile> {
    static var standard: Self {
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

    static var easyGame: Self {
        var cards = Rank.allCases.flatMap { rank in
            Suit.allCases.map { suit in
                StandardDeckCard(rank, of: suit, isFacedUp: false)
            }
        }
        cards.swapAt(0, 28)
        cards.swapAt(2, 29)
        cards.swapAt(1, 5)

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

extension Deck {
    static var standard: Self {
        Deck(
            downwards: IdentifiedArray(uniqueElements: [Card].standard52Deck[28...]),
            upwards: []
        )
    }
}
