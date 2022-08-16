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
        guard let draggingState = state.draggingState else { return .none }

        let dropFrame = state.frames.first { frame in
            frame.rect.contains(draggingState.position)
        }

        let dropEffect = Effect<AppAction, Never>(value: .resetZIndexPriority)
            .delay(for: 0.5, scheduler: environment.mainQueue)
            .eraseToEffect()

        switch dropFrame {
        case let .pile(pileID, _):
            let draggedCards = state.draggedCards
            guard var pile = state.piles[id: pileID],
                  isValidMove(cards: draggedCards, onto: pile.cards.elements)
            else {
                state.draggingState = nil
                return dropEffect
            }

            switch DraggingSource.card(draggingState.card, in: state) {
            case let .pile(pileID?):
                state.removePileCards(pileID: pileID, cards: draggedCards)
            case let .foundation(foundationID?):
                state.foundations[id: foundationID]?.cards.remove(draggingState.card)
            case .deck:
                state.deck.upwards.remove(draggingState.card)
            case .pile, .foundation, .removed:
                state.draggingState = nil
                return dropEffect
            }

            pile.cards.append(contentsOf: draggedCards)
            state.piles.updateOrAppend(pile)

            state.draggingState = nil
            return dropEffect
        case let .foundation(foundationID, _):
            guard
                var foundation = state.foundations[id: foundationID],
                isValidScoring(card: draggingState.card, onto: foundation),
                state.draggedCards.count == 1
            else {
                state.draggingState = nil
                return dropEffect
            }

            switch DraggingSource.card(draggingState.card, in: state) {
            case let .pile(pileID?):
                state.removePileCards(pileID: pileID, cards: [draggingState.card])
            case .deck:
                state.deck.upwards.remove(draggingState.card)
            case .foundation, .pile, .removed:
                state.draggingState = nil
                return dropEffect
            }

            foundation.cards.updateOrAppend(draggingState.card)
            state.foundations.updateOrAppend(foundation)

            state.draggingState = nil
            return dropEffect
        case .deck, .none:
            state.draggingState = nil
            return dropEffect
        }
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

private func isValidMove(cards: [Card], onto: [Card]) -> Bool {
    if onto.count == 0, cards.first?.rank == .king { return true }
    guard let first = cards.first, let onto = onto.last, onto.isFacedUp else { return false }

    let isColorDifferent: Bool
    switch first.suit {
    case .clubs, .spades: isColorDifferent = [.diamonds, .hearts].contains(onto.suit)
    case .diamonds, .hearts: isColorDifferent = [.clubs, .spades].contains(onto.suit)
    }

    let isRankLower = first.rank == onto.rank.lower

    return isColorDifferent && isRankLower
}

private func isValidScoring(card: Card?, onto foundation: Foundation) -> Bool {
    guard let card = card else { return false }
    let canScore = card.rank == .ace || card.rank.lower == foundation.cards.last?.rank
    return card.suit == foundation.suit && canScore
}

extension AppState {

    var draggedCards: [Card] {
        guard let card = draggingState?.card else { return [] }
        switch DraggingSource.card(card, in: self) {
        case let .pile(id):
            guard let id = id, let pile = piles[id: id], let index = pile.cards.firstIndex(of: card) else { return [] }
            return Array(pile.cards[index...])
        case .foundation, .deck, .removed:
            return [card]
        }
    }

    var cardWidth: CGFloat {
        frames.first(where: { if case .pile = $0 { return true } else { return false } })?.rect.width ?? 0
    }

    mutating func removePileCards(pileID: Pile.ID, cards: [Card]) {
        piles[id: pileID]?.cards.removeAll { cards.contains($0) }
        if var lastCard = piles[id: pileID]?.cards.last {
            lastCard.isFacedUp = true
            piles[id: pileID]?.cards.updateOrAppend(lastCard)
        }
    }
}

struct DraggingState: Equatable {
    let card: Card
    var position: CGPoint
}

enum DraggingSource: Equatable {
    case pile(id: Pile.ID?)
    case foundation(id: Foundation.ID?)
    case deck
    case removed

    static func card(_ card: Card, in state: AppState) -> Self {
        if let pileID = state.piles.first(where: { $0.cards.contains(card) })?.id {
            return .pile(id: pileID)
        } else if let foundationID = state.foundations.first(where: { $0.cards.contains(card) })?.id {
            return .foundation(id: foundationID)
        } else if state.deck.upwards.contains(card) {
            return .deck
        }
        return .removed
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

private extension Rank {
    var lower: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self) else { return nil }
        return index > 0 ? Rank.allCases[index - 1] : nil
    }
}
