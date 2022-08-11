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
    var draggedCardsOffsets: [Card: CGSize] = [:]
}

enum AppAction: Equatable {
    case shuffleCards
    case drawCard
    case flipDeck
    case updateFrame(Frame)
    case dragCard(Card, position: CGPoint)
    case dropCards
    case setNamespace(Namespace.ID)
    case updateDraggedCardsOffset
    case resetDraggedCards
    case resetDraggedCardsOffset
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
    case let .dragCard(card, position):
        guard card.isFacedUp else { return .none }
        state.draggingState = DraggingState(card: card, position: position)
        return Effect(value: .updateDraggedCardsOffset)
    case .dropCards:
        guard let draggingState = state.draggingState else { return .none }

        let dropFrame = state.frames.first { frame in
            frame.rect.contains(draggingState.position)
        }
        switch dropFrame {
        case let .pile(pileID, _):
            let draggedCards = state.draggedCards
            guard var pile = state.piles[id: pileID],
                  isValidMove(cards: draggedCards, onto: pile.cards.elements)
            else { return Effect(value: .resetDraggedCards) }

            switch DraggingSource.card(draggingState.card, in: state) {
            case let .pile(pileID?):
                state.removePileCards(pileID: pileID, cards: draggedCards)
            case let .foundation(foundationID?):
                state.foundations[id: foundationID]?.cards.remove(draggingState.card)
            case .deck:
                state.deck.upwards.remove(draggingState.card)
            case .pile, .foundation:
                return Effect(value: .resetDraggedCards)
            }

            pile.cards.append(contentsOf: draggedCards)
            state.piles.updateOrAppend(pile)

            return Effect(value: .resetDraggedCards)
        case let .foundation(foundationID, _):
            guard
                var foundation = state.foundations[id: foundationID],
                isValidScoring(card: draggingState.card, onto: foundation),
                state.draggedCards.count == 1
            else { return Effect(value: .resetDraggedCards) }

            switch DraggingSource.card(draggingState.card, in: state) {
            case let .pile(pileID?):
                state.removePileCards(pileID: pileID, cards: [draggingState.card])
            case .deck:
                state.deck.upwards.remove(draggingState.card)
            case .foundation, .pile:
                return Effect(value: .resetDraggedCards)
            }

            foundation.cards.updateOrAppend(draggingState.card)
            state.foundations.updateOrAppend(foundation)

            return Effect(value: .resetDraggedCards)
        case .deck: return Effect(value: .resetDraggedCards)
        case .none: return Effect(value: .resetDraggedCards)
        }
    case let .setNamespace(namespace):
        state.namespace = namespace
        return .none
    case .updateDraggedCardsOffset:
        guard let origin = state.draggingOrigin,
              let position = state.draggingState?.position
        else { return .none }

        let width = position.x - origin.x - state.cardWidth/2
        let height = position.y - origin.y - state.cardWidth * 7/5

        for card in state.draggedCards {
            state.draggedCardsOffsets[card] = CGSize(width: width, height: height)
        }
        return .none
    case .resetDraggedCards:
        for card in state.draggedCardsOffsets.keys { state.draggedCardsOffsets[card] = .zero }
        state.draggingState = nil
        return Effect(value: .resetDraggedCardsOffset)
            .delay(for: 0.5, scheduler: environment.mainQueue)
            .eraseToEffect()
    case .resetDraggedCardsOffset:
        state.draggedCardsOffsets.removeAll()
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

    var draggedCards: [Card] {
        guard let card = draggingState?.card else { return [] }
        switch DraggingSource.card(card, in: self) {
        case let .pile(id):
            guard let id = id, let pile = piles[id: id], let index = pile.cards.firstIndex(of: card) else { return [] }
            return Array(pile.cards[index...])
        case .foundation, .deck:
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

    func zIndex(source: DraggingSource) -> Double {
        guard let card = draggedCardsOffsets.keys.first else { return 0 }
        let currentlyDraggedSource = DraggingSource.card(card, in: self)
        switch (source, currentlyDraggedSource) {
        case let (.pile(pileID), .pile(currentlyDraggedPileID)):
            return pileID == currentlyDraggedPileID ? 2 : 1
        case let (.foundation(foundationID), .foundation(currentlyDraggedFoundationID)):
            return foundationID == currentlyDraggedFoundationID ? 2 : 1
        case (.deck, .deck), (.foundation, .deck):
            return 1
        default:
            return 0
        }
    }

    var draggingOrigin: CGPoint? {
        guard let card = draggingState?.card ?? draggedCardsOffsets.keys.first
        else { return nil }

        switch DraggingSource.card(card, in: self) {
        case let .pile(pileID):
            return frames.first { frame in
                if case let .pile(id, _) = frame, id == pileID {
                    return true
                } else {
                    return false
                }
            }?.rect.origin
        case let.foundation(foundationID):
            return frames.first { frame in
                if case let .foundation(id, _) = frame, id == foundationID {
                    return true
                } else {
                    return false
                }
            }?.rect.origin
        case .deck:
            return frames.first { if case .deck = $0 { return true } else { return false } }?.rect.origin
        }
    }
}

struct DraggingState: Equatable {
    let card: Card
    var position: CGPoint
}

struct DragCard: Equatable {
    let origin: CGPoint
    let offset: CGSize
}

enum DraggingSource {
    case pile(id: Pile.ID?)
    case foundation(id: Foundation.ID?)
    case deck

    static func card(_ card: Card, in state: AppState) -> Self {
        if let pileID = state.piles.first(where: { $0.cards.contains(card) })?.id {
            return .pile(id: pileID)
        } else if let foundationID = state.foundations.first(where: { $0.cards.contains(card) })?.id {
            return .foundation(id: foundationID)
        } else if state.deck.upwards.contains(card) {
            return .deck
        }
        #if DEBUG
        fatalError("Shouldn't be nil")
        #else
        return .zero
        #endif
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

private extension Suit {
    static var orderedCases: [Self] { [.hearts, .clubs, .diamonds, .spades] }
}

private extension Rank {
    var lower: Rank? {
        guard let index = Rank.allCases.firstIndex(of: self) else { return nil }
        return index > 0 ? Rank.allCases[index - 1] : nil
    }
}
