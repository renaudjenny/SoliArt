import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class ScoreCoreTests: XCTestCase {

    func testIncrementingMove() {
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.shuffleCards = ShuffleCards { .standard52Deck }
        }

        store.send(.drag(.delegate(.scoringMove(.incrementMoveOnly)))) {
            $0.score.moves = 1
        }

        store.send(.drag(.delegate(.scoringMove(.incrementMoveOnly)))) {
            $0.score.moves = 2
        }

        store.send(.game(.confirmResetGame)) {
            $0.game.resetGameConfirmationDialog = .resetGame
        }

        store.send(.game(.resetGame)) {
            $0.score.moves = 0
            $0.game.resetGameConfirmationDialog = nil
            $0.game.isGameOver = false
            $0.game.piles = .standard
            $0.game.deck = .standard
        }
    }

    func testScoring() {
        let store = TestStore(initialState: App.State()) {
            App()
        }

        store.send(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
            $0.score.score = 10
            $0.score.moves = 1
        }

        store.send(.drag(.delegate(.scoringMove(.turnOverPileCard)))) {
            $0.score.score = 15
            $0.score.moves = 2
        }

        store.send(.drag(.delegate(.scoringMove(.moveBackFromFoundation)))) {
            $0.score.score = 0
            $0.score.moves = 3
        }

        for _ in 1...11 {
            store.send(.drag(.delegate(.scoringMove(.moveToFoundation)))) {
                $0.score.score += 10
                $0.score.moves += 1
            }
        }

        store.send(.drag(.delegate(.scoringMove(.recycling)))) {
            $0.score.score = 10
        }

        store.send(.drag(.delegate(.scoringMove(.recycling)))) {
            $0.score.score = 0
        }
    }
}
