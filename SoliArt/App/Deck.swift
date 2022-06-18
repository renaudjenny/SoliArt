import SwiftUICardGame
import ComposableArchitecture

struct Foundation: Equatable, Identifiable {
    let suit: StandardDeckCard.Suit
    var cards: IdentifiedArrayOf<StandardDeckCard>

    var id: String { suit.rawValue }
}

struct Pile: Equatable, Identifiable {
    let id: Int
    var cards: IdentifiedArrayOf<StandardDeckCard>
}

struct Deck: Equatable {
    var downwards: IdentifiedArrayOf<StandardDeckCard>
    var upwards: IdentifiedArrayOf<StandardDeckCard>
}

extension StandardDeckCard: Equatable, Identifiable {
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(rank)
        hasher.combine(suit)
        return hasher.finalize()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
