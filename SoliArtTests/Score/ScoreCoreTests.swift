import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class ScoreCoreTests: XCTestCase {

    func testIncrementingMove() {
        let store = TestStore(initialState: ScoreState(), reducer: scoreReducer, environment: ScoreEnvironment())

        store.send(.incrementMove) {
            $0.moves = 1
        }

        store.send(.incrementMove) {
            $0.moves = 2
        }

        store.send(.resetMove) {
            $0.moves = 0
        }
    }

    func testScoring() {
        let store = TestStore(initialState: ScoreState(), reducer: scoreReducer, environment: ScoreEnvironment())

        store.send(.score(.moveToFoundation)) {
            $0.score = 10
        }

        store.send(.score(.turnOverPileCard)) {
            $0.score = 15
        }

        store.send(.score(.moveBackFromFoundation)) {
            $0.score = 0
        }

        for _ in 1...11 {
            store.send(.score(.moveToFoundation)) {
                $0.score += 10
            }
        }

        store.send(.score(.recycling)) {
            $0.score = 10
        }

        store.send(.score(.recycling)) {
            $0.score = 0
        }
    }
}
