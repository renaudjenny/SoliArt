import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct GameState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
    var deck = Deck(downwards: [], upwards: [])
    var isGameOver = true
    var resetGameConfirmationDialog: ConfirmationDialogState<GameAction>?
}

enum GameAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case confirmResetGame
    case cancelResetGame
    case resetGame
}

struct GameEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
}

let gameReducer = Reducer<GameState, GameAction, GameEnvironment> { state, action, environment in
    switch action {
    case .shuffleCards:
        guard state.isGameOver else { return .none }

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

        state.deck.upwards = []
        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards)

        state.foundations = IdentifiedArrayOf(
            uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
        )

        state.isGameOver = false
        return .none
    case .drawCard:
        let cards = state.deck.downwards
        guard cards.count > 0 else { return .none }

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
        return .none
    case .confirmResetGame:
        state.resetGameConfirmationDialog = .resetGame
        return .none
    case .cancelResetGame:
        state.resetGameConfirmationDialog = nil
        return .none
    case .resetGame:
        state.resetGameConfirmationDialog = nil
        state.isGameOver = true
        return Effect(value: .shuffleCards)
    }
}

extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}

extension GameState {
    var isWinDisplayed: Bool {
        foundations.allSatisfy { $0.cards.last?.rank == .king }
    }
}
