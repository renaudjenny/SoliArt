import SwiftUICardGame
import ComposableArchitecture

struct Foundation: Identifiable {
    let suit: StandardDeckCard.Suit
    var cards: IdentifiedArrayOf<StandardDeckCard>

    var id: String { suit.rawValue }
}

struct Pile: Identifiable {
    let id: Int
    var cards: IdentifiedArrayOf<StandardDeckCard>
}

extension StandardDeckCard: Identifiable {
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(rank)
        hasher.combine(suit)
        return hasher.finalize()
    }
}
