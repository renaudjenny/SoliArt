import ComposableArchitecture
import SwiftUICardGame
import SwiftUI

struct AppState: Equatable {
    var foundations = IdentifiedArrayOf<Foundation>(
        uniqueElements: Suit.orderedCases.map { Foundation(suit: $0, cards: []) }
    )
    var piles = IdentifiedArrayOf<Pile>(uniqueElements: (1...7).map { Pile(id: $0, cards: []) })
    var deck = Deck(downwards: [], upwards: [])
    var score = ScoreState()
    var frames: IdentifiedArrayOf<Frame> = []
    var draggingState: DraggingState?
    var isGameOver = true
    var namespace: Namespace.ID?
    var zIndexPriority: DraggingSource = .pile(id: nil)
    var resetGameAlert: AlertState<AppAction>?
    var hint: Hint?
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCard(Card, position: CGPoint)
    case dropCards
    case doubleTapCard(Card)
    case resetZIndexPriority
    case setNamespace(Namespace.ID)
    case promptResetGame
    case cancelResetGame
    case resetGame
    case score(ScoreAction)
    case hint
    case setHintCardPosition(CGPoint)
    case removeHint
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let shuffleCards: () -> [Card]
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    scoreReducer.pullback(
        state: \.score,
        action: /AppAction.score,
        environment: { _ in ScoreEnvironment() }
    ),
    Reducer { state, action, environment in
        enum CancelID {}

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
            return Effect(value: .score(.score(.recycling)))
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
        case let .doubleTapCard(card):
            guard
                card.isFacedUp,
                let foundation = state.foundations.first(where: { $0.suit == card.suit })
            else { return .none }

            return state.move(card: card, foundation: foundation)
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
            state.score = ScoreState()
            return Effect(value: .shuffleCards)
        case .hint:
            let pileHints: [Hint] = state.piles.flatMap { pile in
                state.foundations.compactMap { foundation in
                    guard let card = pile.cards.last else { return nil }
                    return isValidScoring(card: card, onto: foundation)
                    ? Hint(
                        card: card,
                        origin: .pile(id: pile.id),
                        destination: .foundation(id: foundation.id),
                        cardPosition: state.cardPosition(card)
                    )
                    : nil
                }
            }

            let deckHints: [Hint] = state.foundations.compactMap { foundation in
                guard let card = state.deck.upwards.last else { return nil }
                return isValidScoring(card: state.deck.upwards.last, onto: foundation)
                ? Hint(
                    card: card,
                    origin: .deck,
                    destination: .foundation(id: foundation.id),
                    cardPosition: state.cardPosition(card)
                )
                : nil
            }

            guard let hint = (pileHints + deckHints).first else { return .none }
            state.hint = hint

            let initialPosition = hint.cardPosition
            let destination = state.destinationPosition(hint.destination)
            return .run { send in
                try await environment.mainQueue.sleep(for: 0.5)
                await send(.setHintCardPosition(destination), animation: .linear)
                try await environment.mainQueue.sleep(for: 1)
                await send(.setHintCardPosition(initialPosition))
                try await environment.mainQueue.sleep(for: 1)
                await send(.setHintCardPosition(destination), animation: .linear)
                try await environment.mainQueue.sleep(for: 1)
                await send(.removeHint)
            }
            .cancellable(id: CancelID.self)
        case let .setHintCardPosition(position):
            state.hint?.cardPosition = position
            return .none
        case .removeHint:
            state.hint = nil
            return .none
        case .score:
            return .none
        }
    }
)

extension AppState {
    var cardWidth: CGFloat {
        frames.first(where: { if case .pile = $0 { return true } else { return false } })?.rect.width ?? 0
    }
}

extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}
