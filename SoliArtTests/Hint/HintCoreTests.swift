import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

@MainActor
class HintCoreTests: XCTestCase {
    func testHintToMoveFromPileToFoundation() async {
        let scheduler = DispatchQueue.test
        let store = TestStore(
            initialState: Hint.State(foundations: Game.State().foundations, piles: .easyGame)
        ) {
            Hint()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }
        await store.send(.hint) {
            $0.hint = HintMove(
                card: Card(.ace, of: .diamonds, isFacedUp: true),
                origin: .pile(id: 3),
                destination: .foundation(id: Suit.diamonds.rawValue),
                position: .source
            )
        }
        await scheduler.advance(by: .seconds(0.5))
        await store.receive(.setHintCardPosition(.destination)) {
            $0.hint?.position = .destination
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.setHintCardPosition(.source)) {
            $0.hint?.position = .source
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.setHintCardPosition(.destination)) {
            $0.hint?.position = .destination
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.removeHint) {
            $0.hint = nil
        }
    }

    func testHintToMoveFromDeckToFoundation() async {
        let scheduler = DispatchQueue.test
        var piles = IdentifiedArrayOf<Pile>.standard
        piles[id: 1]?.cards.remove(Card(.ace, of: .clubs, isFacedUp: true))
        let store = TestStore(
            initialState: Hint.State(
                foundations: Game.State().foundations,
                piles: piles,
                deck: Deck(downwards: [], upwards: IdentifiedArrayOf(uniqueElements: [
                    Card(.ace, of: .clubs, isFacedUp: true)
                ]))
            )
        ) {
            Hint()
        } withDependencies: {
            $0.mainQueue = scheduler.eraseToAnyScheduler()
        }

        await store.send(.hint) {
            $0.hint = HintMove(
                card: Card(.ace, of: .clubs, isFacedUp: true),
                origin: .deck,
                destination: .foundation(id: Suit.clubs.rawValue),
                position: .source
            )
        }
        await scheduler.advance(by: .seconds(0.5))
        await store.receive(.setHintCardPosition(.destination)) {
            $0.hint?.position = .destination
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.setHintCardPosition(.source)) {
            $0.hint?.position = .source
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.setHintCardPosition(.destination)) {
            $0.hint?.position = .destination
        }
        await scheduler.advance(by: .seconds(1))
        await store.receive(.removeHint) {
            $0.hint = nil
        }
    }
}
