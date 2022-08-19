import ComposableArchitecture
@testable import SoliArt
import SwiftUICardGame
import XCTest

class ScoreCoreTests: XCTestCase {

    func testIncrementingMove() {
        let store = TestStore(initialState: ScoreState(), reducer: scoreReducer, environment: ScoreEnvironment())

        store.send(.incrementMove) {
            $0.move = 1
        }

        store.send(.incrementMove) {
            $0.move = 2
        }

        store.send(.resetMove) {
            $0.move = 0
        }
    }
}
