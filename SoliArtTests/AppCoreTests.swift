import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class AppCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<AppState, AppState, AppAction, AppAction, AppEnvironment>!
    private let now = Date(timeIntervalSince1970: 0)

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(mainQueue: .main, shuffleCards: { [Card].standard52Deck }, now: { self.now })
        )
    }

    func testFlipDeck() {
        store.send(.game(.flipDeck))

        store.receive(.history(.addEntry(GameState()))) {
            $0.history.entries.append(HistoryEntry(date: self.now, gameState: GameState()))
        }

        store.receive(.score(.score(.recycling)))
    }

    func testResetGame() {
        store.send(.score(.score(.moveToFoundation))) {
            $0.score.score = 10
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 1
        }

        store.send(.game(.resetGame)) {
            $0.score = ScoreState()
        }
    }

    func testGameActionThatUpdateState() {
        let gameStateAfterShuffle = GameState(
            foundations: GameState().foundations,
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
        store.receive(.history(.addEntry(gameStateAfterShuffle))) {
            $0.history.entries = [HistoryEntry(date: self.now, gameState: gameStateAfterShuffle)]
        }

        var gameStateAfterDrawingCard = gameStateAfterShuffle
        var drawnCard = gameStateAfterDrawingCard.deck.downwards.removeFirst()
        drawnCard.isFacedUp = true
        gameStateAfterDrawingCard.deck.upwards = [drawnCard]
        store.send(.game(.drawCard)) {
            $0.game = gameStateAfterDrawingCard
        }
        store.receive(.history(.addEntry(gameStateAfterDrawingCard))) {
            $0.history.entries.append(HistoryEntry(date: self.now, gameState: gameStateAfterDrawingCard))
        }

        var gameStateAfterDoubleTappingCard = gameStateAfterDrawingCard
        let aceOfClubs = Card(.ace, of: .clubs, isFacedUp: true)
        gameStateAfterDoubleTappingCard.foundations[id: Suit.clubs.rawValue]!.cards.append(aceOfClubs)
        gameStateAfterDoubleTappingCard.piles[id: 1]!.cards = []
        store.send(.drag(.doubleTapCard(aceOfClubs))) {
            $0.game = gameStateAfterDoubleTappingCard
        }
        store.receive(.drag(.score(.score(.moveToFoundation))))
        store.receive(.history(.addEntry(gameStateAfterDoubleTappingCard))) {
            $0.history.entries.append(HistoryEntry(date: self.now, gameState: gameStateAfterDoubleTappingCard))
        }
        store.receive(.score(.score(.moveToFoundation))) {
            $0.score.score = 10
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 1
        }

        // pile 5 on pile 3
        var gameStateAfterDraggingCard = gameStateAfterDoubleTappingCard
        let draggedCard = Card(.two, of: .diamonds, isFacedUp: true)
        let frame = CGRect(x: 100, y: 100, width: 200, height: 400)
        store.send(.drag(.updateFrame(.pile(2, frame)))) {
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
        store.receive(.history(.addEntry(gameStateAfterDraggingCard))) {
            $0.history.entries.append(HistoryEntry(date: self.now, gameState: gameStateAfterDraggingCard))
        }
        store.receive(.score(.score(.turnOverPileCard))) {
            $0.score.score = 15
        }
        store.receive(.score(.incrementMove)) {
            $0.score.moves = 2
        }
    }
}
