import ComposableArchitecture
import SwiftUICardGame
import SwiftUI

struct AppState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
    var deck = Deck(downwards: [], upwards: [])
    var score = 0
    var moves = 0
    var draggedCard: DragCard?
    var dragOrigin: DragOrigin?
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case dragCard(DragCard?)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .shuffleCards:
        var cards = environment.shuffleCards()

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
    case .drawCard:
        let cards = state.deck.downwards
        let upwardsToAdd: [Card] = cards[..<1].map {
            var card = $0
            card.isFacedUp = true
            return card
        }
        state.deck.upwards = IdentifiedArrayOf(uniqueElements: state.deck.upwards.elements + upwardsToAdd)
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards[1...])
        return .none
    case .flipDeck:
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: state.deck.upwards.map {
            var card = $0
            card.isFacedUp = false
            return card
        })
        state.deck.upwards = []
        return Effect(value: .drawCard).delay(for: 0.4, scheduler: environment.mainQueue).eraseToEffect()
    case let .dragCard(dragCard):
        guard let card = dragCard?.card else {
            state.draggedCard = nil
            state.dragOrigin = nil
            return .none
        }

        state.draggedCard = dragCard

        guard let pile = state.piles.first(where: { $0.cards.contains(card) }) else { return .none }
        state.dragOrigin = .pile(pile)

        return .none
    }
}

struct DragCard: Equatable {
    let card: Card
    var position: CGPoint
}

enum DragOrigin: Equatable {
    case pile(Pile)
}

private extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}
