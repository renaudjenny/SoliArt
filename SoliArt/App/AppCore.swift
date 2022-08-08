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
    var draggedCards: DragCards?
    var isGameOver = true
    var namespace: Namespace.ID?
    var draggedCardsOffsets: [DragCards.Origin: CGSize] = [:]
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCards(DragCards?)
    case dropCards(DragCards)
    case setNamespace(Namespace.ID)
    case updateDraggedCardsOffset(origin: DragCards.Origin)
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

        state.deck.downwards = IdentifiedArrayOf(uniqueElements: cards)

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
    case let .dragCards(dragCards):
        guard let dragCards = dragCards else {
            let draggedCards = state.draggedCards
            state.draggedCards = nil
            return draggedCards.map { Effect(value: .dropCards($0)) } ?? .none
        }
        guard dragCards.origin.cards.allSatisfy({ $0.isFacedUp }) else { return .none }
        state.draggedCards = dragCards
        return Effect(value: .updateDraggedCardsOffset(origin: dragCards.origin))
    case let .dropCards(dragCards):
        let updateDraggedCardsOffsetEffect: Effect<AppAction, Never> = Effect(
            value: .updateDraggedCardsOffset(origin: dragCards.origin)
        )

        let dropFrame = state.frames.first { frame in
            frame.rect.contains(dragCards.position)
        }
        switch dropFrame {
        case let .pile(pileID, _):
            guard var pile = state.piles[id: pileID],
                  isValidMove(cards: dragCards.origin.cards, onto: pile.cards.elements)
            else { return updateDraggedCardsOffsetEffect }

            switch dragCards.origin {
            case let .pile(pileID, cards):
                state.removePileCards(pileID: pileID, cards: cards)
            case let .foundation(foundationID, card):
                state.foundations[id: foundationID]?.cards.remove(card)
            case let .deck(card):
                state.deck.upwards.remove(card)
            }

            pile.cards.append(contentsOf: dragCards.origin.cards)
            state.piles.updateOrAppend(pile)

            return updateDraggedCardsOffsetEffect
        case let .foundation(foundationID, _):
            guard
                var foundation = state.foundations[id: foundationID],
                let card = dragCards.origin.cards.first,
                isValidScoring(card: card, onto: foundation)
            else { return updateDraggedCardsOffsetEffect }

            switch dragCards.origin {
            case let .pile(pileID, cards):
                state.removePileCards(pileID: pileID, cards: cards)
            case let .foundation(foundationID, card):
                return .none
            case let .deck(card):
                state.deck.upwards.remove(card)
            }

            foundation.cards.updateOrAppend(card)
            state.foundations.updateOrAppend(foundation)

            return updateDraggedCardsOffsetEffect
        case .deck: return updateDraggedCardsOffsetEffect
        case .none: return updateDraggedCardsOffsetEffect
        }
    case let .setNamespace(namespace):
        state.namespace = namespace
        return .none
    case let .updateDraggedCardsOffset(origin):
        guard let draggedCards = state.draggedCards,
              draggedCards.origin ~= origin,
              let frameOrigin = origin.frame(state: state)?.rect.origin
        else {
            state.draggedCardsOffsets.removeAll()
            return .none
        }
        let position = draggedCards.position
        let width = position.x - frameOrigin.x - state.cardWidth/2
        let height = position.y - frameOrigin.y - state.cardWidth * 7/5
        state.draggedCardsOffsets[origin] = CGSize(width: width, height: height)
        return .none
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
    func card(id: Card.ID) -> Card? {
        piles.flatMap(\.cards).first { $0.id == id }
            ?? foundations.flatMap(\.cards).first { $0.id == id }
            ?? deck.upwards.first { $0.id == id }
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

    enum ZIndexSource {
        case pile(Pile.ID?)
        case foundation(Foundation.ID?)
        case deck
    }

    func zIndex(source: ZIndexSource) -> Double {
        switch source {
        case let .pile(pileID):
            if case let .pile(draggedPileID, _) = draggedCardsOffsets.first?.key {
                return pileID == draggedPileID ? 2 : 1
            }
        case let .foundation(foundationID):
            if case let .foundation(draggedFoundationID, _) = draggedCardsOffsets.first?.key {
                return foundationID == draggedFoundationID ? 2 : 1
            } else if case .deck = draggedCardsOffsets.first?.key {
                return 1
            }
        case .deck:
            if case .deck = draggedCardsOffsets.first?.key {
                return 1
            }
        }
        return 0
    }
}

struct DragCards: Equatable {
    enum Origin: Equatable, Hashable {
        case pile(id: Pile.ID, cards: [Card])
        case foundation(id: Foundation.ID, card: Card)
        case deck(card: Card)

        var cards: [Card] {
            switch self {
            case let .pile(_, cards): return cards
            case let .foundation(_, card), let .deck(card): return [card]
            }
        }
    }

    let origin: Origin
    var position: CGPoint
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

private extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}

private extension Rank {
    var lower: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self) else { return nil }
        return index > 0 ? Rank.allCases[index - 1] : nil
    }
}

extension DragCards.Origin {
    func frame(state: AppState) -> Frame? {
        switch self {
        case let .pile(id: pileID, _):
            return state.frames.first { frame in
                if case let .pile(id, _) = frame, id == pileID {
                    return true
                } else {
                    return false
                }
            }
        case let.foundation(id: foundationID, _):
            return state.frames.first { frame in
                if case let .foundation(id, _) = frame, id == foundationID {
                    return true
                } else {
                    return false
                }
            }
        case .deck:
            return state.frames.first { if case .deck = $0 { return true } else { return false } }
        }
    }

    static func ~= (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (let .pile(lhsID, lhsCards), let .pile(rhsID, rhsCards)):
            guard lhsID == rhsID else { return false }
            return rhsCards.allSatisfy { lhsCards.contains($0) }
        case (let .foundation(lhsID, _), let .foundation(rhsID, _)): return lhsID == rhsID
        case (.deck, .deck): return true
        case (.pile, _), (.foundation, _), (.deck, _): return false
        }
    }
}
