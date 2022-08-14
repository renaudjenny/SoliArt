import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct CardBackground: View {
    var body: some View {
        Image("CardBackground").resizable()
    }
}

typealias Card = StandardDeckCard

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
