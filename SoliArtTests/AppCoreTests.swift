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
            $0.piles = IdentifiedArrayOf(uniqueElements: [
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

            $0.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[28...])
        }
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
