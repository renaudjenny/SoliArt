import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class HintCoreTests: XCTestCase {
    private var scheduler: TestSchedulerOf<DispatchQueue>!
    private var store: TestStore<HintState, HintState, HintAction, HintAction, HintEnvironment>!

    @MainActor override func setUp() async throws {
        scheduler = DispatchQueue.test
        store = TestStore(
            initialState: HintState(),
            reducer: hintReducer,
            environment: HintEnvironment(mainQueue: .main)
        )
    }

    func testHintToMoveFromPileToFoundation() {
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: .testEasyGame(scheduler: scheduler)
        )

        shuffleCards(
            initialCards: AppEnvironment.superEasyGame.shuffleCards(),
            pilesAfterShuffle: Self.pilesAfterShuffleForEasyGame()
        )

        let cardWidth: Double = 100

        let foundationFrame: Frame = .foundation(Suit.clubs.rawValue, CGRect(x: 20, y: 20, width: cardWidth, height: 200))
        store.send(.updateFrame(foundationFrame)) {
            $0.frames.updateOrAppend(foundationFrame)
        }

        let pileFrame: Frame = .pile(1, CGRect(x: 40, y: 40, width: cardWidth, height: 400))
        store.send(.updateFrame(pileFrame)) {
            $0.frames.updateOrAppend(pileFrame)
        }

        let initialPosition = CGPoint(
            x: pileFrame.rect.minX + cardWidth/2,
            y: pileFrame.rect.minY + (cardWidth * 7/5)/2
        )
        store.send(.hint) {
            $0.hint = Hint(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .pile(id: 1),
                destination: .foundation(id: Suit.clubs.rawValue),
                cardPosition: initialPosition
            )
        }
    }

    func testHintToMoveFromDeckToFoundation() {
        store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(
                mainQueue: scheduler.eraseToAnyScheduler(),
                shuffleCards: { .easyFromTheDeck }
            )
        )

        shuffleCards(
            initialCards: .easyFromTheDeck,
            pilesAfterShuffle: Self.pilesAfterShuffleForEasyFromTheDeck()
        )

        let cardWidth: Double = 100

        let foundationFrame: Frame = .foundation(Suit.clubs.rawValue, CGRect(x: 20, y: 20, width: cardWidth, height: 200))
        store.send(.updateFrame(foundationFrame)) {
            $0.frames.updateOrAppend(foundationFrame)
        }

        let pileFrame: Frame = .pile(1, CGRect(x: 40, y: 40, width: cardWidth, height: 400))
        store.send(.updateFrame(pileFrame)) {
            $0.frames.updateOrAppend(pileFrame)
        }

        let deckFrame: Frame = .deck(CGRect(x: 200, y: 20, width: cardWidth, height: cardWidth * 7/5))
        store.send(.updateFrame(deckFrame)) {
            $0.frames.updateOrAppend(deckFrame)
        }

        let initialPosition = CGPoint(
            x: deckFrame.rect.minX + cardWidth/2,
            y: deckFrame.rect.minY + (cardWidth * 7/5)/2
        )

        store.send(.drawCard) {
            var facedUpCard = self.cards[28]
            facedUpCard = Card(.ace, of: .clubs, isFacedUp: true)
            $0.deck.upwards = IdentifiedArrayOf(uniqueElements: [facedUpCard])
            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: self.cards[29...])
        }

        store.send(.hint) {
            $0.hint = Hint(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .deck,
                destination: .foundation(id: Suit.clubs.rawValue),
                cardPosition: initialPosition
            )
        }
    }
}
