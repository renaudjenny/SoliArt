import ComposableArchitecture
import SwiftUI
import SwiftUICardGame

struct Game: ReducerProtocol {
    struct State: Equatable {
        var foundations = IdentifiedArrayOf<Foundation>(
            uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
        )
        var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
        var deck = Deck(downwards: [], upwards: [])
        var isGameOver = true
        var resetGameConfirmationDialog: ConfirmationDialogState<Game.Action>?
    }

    enum Action: Equatable {
        case shuffleCards
        case drawCard
        case flipDeck
        case confirmResetGame
        case cancelResetGame
        case resetGame
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.shuffleCards) var shuffleCards

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .shuffleCards:
            return shuffleCards(state: &state)
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
            guard state.deck.downwards.count == 0 && state.deck.upwards.count > 1 else { return .none }
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
            return shuffleCards(state: &state)
        }
    }

    private func shuffleCards(state: inout State) -> EffectTask<Action> {
        guard state.isGameOver else { return .none }

        var cards = shuffleCards()

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
    }
}

extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}

extension Game.State {
    var isWinDisplayed: Bool {
        foundations.allSatisfy { $0.cards.last?.rank == .king }
    }
}
