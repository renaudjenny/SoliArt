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
    var frames: IdentifiedArrayOf<Frame> = []
    var draggingState: DraggingState?
    var isGameOver = true
    var namespace: Namespace.ID?
    var zIndexPriority: DraggingSource = .pile(id: nil)
    var resetGameAlert: AlertState<AppAction>?
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCard(Card, position: CGPoint)
    case dropCards
    case resetZIndexPriority
    case setNamespace(Namespace.ID)
    case promptResetGame
    case cancelResetGame
    case resetGame
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
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
    case let .updateFrame(frame):
        state.frames.updateOrAppend(frame)
        return .none
    case let .dragCard(card, position):
        guard card.isFacedUp else { return .none }
        state.draggingState = DraggingState(card: card, position: position)
        state.zIndexPriority = DraggingSource.card(card, in: state)
        return .none
    case .dropCards:
        return state.dropCards(mainQueue: environment.mainQueue)
    case .resetZIndexPriority:
        state.zIndexPriority = .pile(id: nil)
        return .none
    case let .setNamespace(namespace):
        state.namespace = namespace
        return .none
    case .promptResetGame:
        state.resetGameAlert = .resetGame
        return .none
    case .cancelResetGame:
        state.resetGameAlert = nil
        return .none
    case .resetGame:
        state.resetGameAlert = nil
        state.isGameOver = true
        return Effect(value: .shuffleCards)
    }
}

extension AppState {
    var cardWidth: CGFloat {
        frames.first(where: { if case .pile = $0 { return true } else { return false } })?.rect.width ?? 0
    }
}

enum Frame: Equatable, Hashable, Identifiable {
    case pile(Pile.ID, CGRect)
    case foundation(Foundation.ID, CGRect)
    case deck(CGRect)

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .pile(pileID, _):
            hasher.combine("Pile")
            hasher.combine(pileID)
        case let .foundation(foundationID, _):
            hasher.combine("Foundation")
            hasher.combine(foundationID)
        case .deck:
            hasher.combine("Deck")
        }
    }

    var id: Int { hashValue }

    var rect: CGRect {
        switch self {
        case let .pile(_, rect), let .foundation(_, rect), let .deck(rect): return rect
        }
    }
}

extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}
