import ComposableArchitecture
import SwiftUICardGame

struct AppState {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: StandardDeckCard.Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
}

private extension StandardDeckCard.Suit {
    static var orderedCases: [Self] { [.hearts, .spades, .diamonds, .spades] }
}
