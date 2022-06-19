import ComposableArchitecture
import SwiftUICardGame

struct AppState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: StandardDeckCard.Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
    var deck = Deck(downwards: [], upwards: [])
    var score = 0
    var moves = 0
}

enum AppAction: Equatable {
    case shuffleCards([StandardDeckCard])
    case cardTapped(rank: StandardDeckCard.Rank, suit: StandardDeckCard.Suit)
}

struct AppEnvironment {
    let shuffleCards: ([StandardDeckCard]) -> [StandardDeckCard]
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case let .shuffleCards(cards):
        var cards = environment.shuffleCards(cards)

        state.piles = IdentifiedArrayOf(uniqueElements: state.piles.map {
            var pile = $0
            pile.cards = IdentifiedArrayOf(uniqueElements: cards[..<$0.id])
            cards = Array(cards[$0.id...])

            if var last = pile.cards.last {
                last.isFacedUp = true
                pile.cards.updateOrAppend(last)
            }

            return pile
        })

        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards)

        return .none
    case let .cardTapped(rank, suit):
        return .none
    }
}

private extension StandardDeckCard.Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}
