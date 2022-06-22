import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct CardBackground: View {
    var body: some View {
        Image("CardBackground").resizable()
    }
}

typealias Card = StandardDeckCard<CardBackground>

struct Foundation: Equatable, Identifiable {
    let suit: Suit
    var cards: IdentifiedArrayOf<Card>

    var id: String { suit.rawValue }
}

struct Pile: Equatable, Identifiable {
    let id: Int
    var cards: IdentifiedArrayOf<Card>
}

struct Deck: Equatable {
    var downwards: IdentifiedArrayOf<Card>
    var upwards: IdentifiedArrayOf<Card>
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

extension Array where Element == Card {
    static var standard52Deck: Self {
        StandardDeckCard.standard52Deck { CardBackground() }
    }
}
