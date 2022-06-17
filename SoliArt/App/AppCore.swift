import ComposableArchitecture
import SwiftUICardGame

struct AppState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: StandardDeckCard.Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
}

enum AppAction: Equatable {

}

struct AppEnvironment {

}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    return .none
}

private extension StandardDeckCard.Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}
